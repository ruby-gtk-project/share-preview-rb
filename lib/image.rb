# frozen_string_literal: true

require 'uri'

require 'gdk_pixbuf2'

require_relative 'http_client'
require_relative 'social'

# Image is one candidate image found in a page: its url, its bytes once
# fetched, and the checks that decide whether a platform would accept it.
#
# Ported from upstream's src/backend/image.rs: the `Image` struct with
# `fetch`, `check`, `thumbnail` and `size`, and the `ImageError` enum with the
# message each variant renders. Upstream decodes and resizes with the `image`
# crate; the port uses GdkPixbuf, which ships with the GTK bindings and
# recognises the same four formats.
class Image
  # Raised by every failure upstream models as an `ImageError` variant. The
  # message is the text upstream's Display impl writes, and `kind` is the
  # variant, which the card builder logs at different levels.
  class ImageError < StandardError
    attr_reader :kind

    def initialize(kind, message)
      super(message)
      @kind = kind
    end

    class << self
      def url_error(info) = new(:url_error, format('Image Url Error: %{info}', info: info))

      def data_url_error(info) = new(:data_url_error, format('Image Data Url Error: %{info}', info: info))

      def invalid_base64(info) = new(:invalid_base64, format('Image Data Invalid Base64: %{info}', info: info))

      def fetch_error(info) = new(:fetch_error, format('Network Error: %{info}', info: info))

      def request_error(info) = new(:request_error, format('Request Error: %{info}', info: info))

      def image_error(info) = new(:image_error, format('Image Error: %{info}', info: info))

      def too_tiny(actual, min)
        new(
          :too_tiny,
          format(
            'Image is too tiny (%{actual}), minimum dimensions are %{min}',
            actual: actual,
            min:    min,
          ),
        )
      end

      def too_heavy(actual, max)
        new(
          :too_heavy,
          format(
            'Image is too heavy (%{actual}), max size is %{max}',
            actual: actual,
            max:    max,
          ),
        )
      end

      def unsupported(info) = new(:unsupported, format('Image is unsupported: %{info}', info: info))

      def unexpected = new(:unexpected, 'Unexpected Error')
    end
  end

  DATA_URL = %r{\Adata:(?<mime>[^,;]*)(?<parameters>;[^,]*)?,(?<body>.*)\z}m

  attr_reader :base_url, :url, :was_relative

  # Upstream's `Image::new` turns a relative url absolute against the page url
  # and fails the whole Image when the url cannot be parsed at all.
  def initialize(url, base_url)
    @base_url = base_url
    @url, @was_relative = absolute(url.to_s.strip, base_url)
    @bytes = nil
    @format = nil
    @width = nil
    @height = nil
    @byte_size = nil
  end

  # Builds an Image, or nil when the url is unusable — the shape upstream's
  # `if let Ok(image) = Image::new(..)` callers want.
  def self.build(url, base_url)
    new(url, base_url)
  rescue ImageError
    nil
  end

  # Fetches the image and returns its bytes. The bytes, format and byte size
  # are kept after the first fetch, as upstream's RefCell/Cell fields are.
  def fetch
    @bytes ||= download
  end

  # Checks the image against one platform's limits and returns the first size
  # kind it fits. Raises ImageError when it fits none of them.
  def check(social, kinds, constraints)
    fetch
    measure

    heavy = @byte_size && @byte_size > constraints[:image_size]
    if heavy
      raise ImageError.too_heavy(
        self.class.human_bytes(@byte_size),
        self.class.human_bytes(constraints[:image_size]),
      )
    end

    if @format && !constraints[:image_formats].include?(@format)
      raise ImageError.unsupported('Format is unsupported')
    end

    matching_kind(social, kinds)
  end

  # Scales the image to cover width×height, crops the overflow away and
  # returns PNG bytes, which any GdkTexture can load.
  def thumbnail(width, height)
    pixbuf = decode(fetch)
    fill(pixbuf, width, height).save(nil, 'png')
  rescue GdkPixbuf::PixbufError, GLib::Error, ImageError => e
    raise ImageError.image_error(e.message)
  end

  # The measured dimensions, or [0, 0] when #check never ran — the same
  # contract as upstream's `size()`.
  def size = [@width || 0, @height || 0]

  def byte_size = @byte_size

  def format = @format

  def to_s = @url.to_s

  # 1024-based, one decimal, matching the `human_bytes` crate upstream
  # formats its too-heavy message with.
  def self.human_bytes(bytes)
    units = %w[B KiB MiB GiB TiB]
    index = 0
    value = bytes.to_f
    while value >= 1024 && index < units.length - 1
      value /= 1024
      index += 1
    end
    format('%<value>.1f %<unit>s', value: value, unit: units[index])
  end

  private

    def absolute(url, base_url)
      parsed = URI.parse(url)
      case parsed
      when URI::HTTP, URI::Generic
        resolve(parsed, url, base_url)
      else
        [parsed, false]
      end
    rescue URI::InvalidURIError => e
      raise ImageError.url_error(e.message)
    end

    # A url with no scheme is relative: upstream joins it onto the page url
    # and records that it was relative, because Twitter rejects those.
    def resolve(parsed, url, base_url)
      case parsed.scheme
      when nil
        [URI.join(base_url, url), true]
      else
        [parsed, false]
      end
    rescue URI::BadURIError, URI::InvalidURIError, URI::InvalidComponentError => e
      raise ImageError.url_error(e.message)
    end

    def download
      case @url.scheme
      when 'data' then decode_data_url
      else request
      end
    end

    def decode_data_url
      match = DATA_URL.match(@url.to_s)
      unless match
        raise ImageError.data_url_error('Not a valid data url')
      end

      body = decode_data_body(match[:body], match[:parameters].to_s.include?('base64'))
      @byte_size ||= body.bytesize
      @format ||= guess_format(body)
      body
    end

    def decode_data_body(body, base64)
      case base64
      when true then body.gsub(/\s+/, '').unpack1('m0')
      else URI.decode_www_form_component(body).b
      end
    rescue ArgumentError => e
      raise ImageError.invalid_base64(e.message)
    end

    def request
      response = fetch_response

      unless response.success?
        raise ImageError.request_error(response.reason)
      end

      @byte_size ||= response.body.bytesize
      @format ||= guess_format(response.body)
      response.body
    end

    def fetch_response
      HttpClient.get(@url)
    rescue HttpClient::NetworkError => e
      raise ImageError.fetch_error(e.message)
    end

    # Measures the image once, the way upstream only loads it when width and
    # height are both still unset.
    def measure
      if @width.nil? && @height.nil?
        decode(@bytes).then do |pixbuf|
          @width = pixbuf.width
          @height = pixbuf.height
        end
      end
    end

    def matching_kind(social, kinds)
      minimum = [0, 0]

      kind = kinds.find do |candidate|
        minimum = social.image_size(candidate)[:minimum]
        fits?(social, candidate, minimum)
      end

      unless kind
        raise ImageError.too_tiny(
          "#{@width}×#{@height}px",
          "#{minimum[0]}×#{minimum[1]}px",
        )
      end

      kind
    end

    # Mastodon only renders its extended preview for landscape images, so a
    # portrait image never matches the Large kind.
    def fits?(social, kind, minimum)
      big_enough = @width >= minimum[0] && @height >= minimum[1]
      landscape_needed = social == Social::MASTODON && kind == Social::LARGE

      case [big_enough, landscape_needed]
      in [true, true] then @width > @height
      in [true, false] then true
      else false
      end
    end

    def decode(bytes)
      unless bytes
        raise ImageError.unexpected
      end

      loader = GdkPixbuf::PixbufLoader.new
      loader.last_write(bytes)
      @format ||= loader.format&.name
      loader.pixbuf.then do |pixbuf|
        unless pixbuf
          raise ImageError.unexpected
        end

        pixbuf
      end
    rescue GdkPixbuf::PixbufError, GLib::Error => e
      raise ImageError.image_error(e.message)
    end

    def guess_format(bytes)
      GdkPixbuf::Pixbuf.get_file_info_from_bytes(GLib::Bytes.new(bytes))&.first&.name
    rescue GdkPixbuf::PixbufError, GLib::Error, NoMethodError
      nil
    end

    # Upstream's resize_to_fill: scale to cover the box, then crop the excess
    # off both sides.
    def fill(pixbuf, width, height)
      scale = [width.to_f / pixbuf.width, height.to_f / pixbuf.height].max
      scaled = pixbuf.scale(
        [(pixbuf.width * scale).ceil, width].max,
        [(pixbuf.height * scale).ceil, height].max,
        :bilinear,
      )
      scaled.subpixbuf(
        ((scaled.width - width) / 2.0).floor,
        ((scaled.height - height) / 2.0).floor,
        width,
        height,
      )
    end
end
