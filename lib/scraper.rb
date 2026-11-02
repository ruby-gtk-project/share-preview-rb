# frozen_string_literal: true

require 'uri'

require_relative 'data'
require_relative 'http_client'
require_relative 'image'

# Scraper requests a page and reads the title, meta tags, icons and body
# images out of its HTML.
#
# Ported from upstream's src/backend/scraper.rs: `scrape`, `get_html_data`,
# `get_attr_val`, `is_image`, `get_favicon` and the `Error` enum. Upstream
# parses with the `scraper` crate; the port has no HTML parser available, so
# it scans the four tags upstream looks at — title, meta, link and img — and
# reads their attributes, which is all those lookups ever touch.
module Scraper
  # The meta tags whose content is treated as an image url.
  IMAGE_TAGS = ['og:image', 'twitter:image', 'twitter:image:src'].freeze

  ICON_RELS = ['shortcut icon', 'icon'].freeze

  IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png'].freeze

  TITLE = %r{<title[^>]*>(?<body>.*?)</title>}im
  TAG = /<(?<name>meta|link|img)\b(?<attributes>[^>]*)>/i
  ATTRIBUTE = /(?<key>[\w:.-]+)\s*=\s*(?:"(?<double>[^"]*)"|'(?<single>[^']*)'|(?<bare>[^\s"'>]+))/
  ENTITY = /&(?:#(?<decimal>\d+)|#x(?<hex>[0-9a-f]+)|(?<name>[a-z]+));/i

  NAMED_ENTITIES = {
    'amp'  => '&',
    'lt'   => '<',
    'gt'   => '>',
    'quot' => '"',
    'apos' => "'",
    'nbsp' => ' ',
  }.freeze

  # Raised when the page could not be read.
  #
  # Ported from upstream's `Error` enum: `NetworkError` for a request that
  # never answered, `Unexpected` for an answer that was not a success, which
  # carries the status the window shows.
  class Error < StandardError
    NETWORK_ERROR = :network_error
    UNEXPECTED    = :unexpected

    attr_reader :kind, :status

    def initialize(kind, status = '')
      @kind = kind
      @status = status.to_s
      case kind
      when NETWORK_ERROR then super("NetworkError:  #{status}")
      else super("UnexpectedError: Error #{status}")
      end
    end
  end

  class << self
    # Requests the url and returns the Data scraped from it.
    def scrape(url)
      uri = URI.parse(url.to_s)

      response = fetch(uri)

      unless response.success?
        raise Error.new(Error::UNEXPECTED, response.status)
      end

      build(response.body, uri)
    end

    private

      def fetch(uri)
        HttpClient.get(uri)
      rescue HttpClient::NetworkError => e
        raise Error.new(Error::NETWORK_ERROR, e.message)
      end

      def build(body, uri)
        icons = []

        PageData.new(url: uri.host.to_s).tap do |data|
          data.title = document_title(body)
          read_tags(
            body,
            data,
            uri,
            icons,
          )
          data.favicon = favicon(uri, icons)
        end
      end

      def document_title(body)
        TITLE.match(body).then do |match|
          case match
          when nil then nil
          else unescape(match[:body]).strip
          end
        end
      end

      def read_tags(body, data, uri, icons)
        body.scan(TAG) do
          name, attributes = Regexp.last_match[:name].downcase, attributes_of(Regexp.last_match[:attributes])

          case name
          when 'meta' then read_meta(attributes, data, uri)
          when 'link' then read_icon(attributes, icons)
          when 'img' then read_body_image(attributes, data, uri)
          end
        end
      end

      # Upstream keeps a meta only when it has a name or at least one
      # property value.
      def read_meta(attributes, data, uri)
        name = attributes['name']
        property = attributes.fetch('property', '').split(' ').reject(&:empty?)
        content = attributes['content']

        unless name.nil? && property.empty?
          data.metadata.push(
            Meta.new(
              name:     name,
              property: property,
              content:  content,
              image:    meta_image(
                name,
                property,
                content,
                uri,
              ),
            ),
          )
        end
      end

      def meta_image(name, property, content, uri)
        case [image_tag?(name, property), content]
        in [true, String => value] then Image.build(value, uri)
        else nil
        end
      end

      def image_tag?(name, property)
        IMAGE_TAGS.any? { |tag| property.include?(tag) || name == tag }
      end

      def read_icon(attributes, icons)
        case [attributes['rel'], attributes['href']]
        in [String => rel, String => href] if ICON_RELS.include?(rel)
          icons.push(href)
        else
          nil
        end
      end

      # Upstream only keeps body images whose src looks like a JPEG or a PNG.
      def read_body_image(attributes, data, uri)
        source = attributes['src'].to_s.strip

        if IMAGE_EXTENSIONS.any? { |extension| source.include?(extension) }
          Image.build(source, uri).then do |image|
            if image
              data.body_images.push(image)
            end
          end
        end
      end

      # The captures are taken from the scan's own arrays rather than from
      # Regexp.last_match, which by then holds only the final match.
      def attributes_of(text)
        text.scan(ATTRIBUTE).each_with_object({}) do |(key, double, single, bare), attributes|
          attributes[key.downcase] ||= attribute_value(double || single || bare || '')
        end
      end

      # Upstream's get_attr_val: trimmed, with newlines flattened to spaces.
      def attribute_value(value) = unescape(value).strip.tr("\n", ' ')

      def unescape(text)
        text.gsub(ENTITY) do
          match = Regexp.last_match
          case match
          in {decimal: String => digits} then digits.to_i.chr(Encoding::UTF_8)
          in {hex: String => digits} then digits.to_i(16).chr(Encoding::UTF_8)
          else NAMED_ENTITIES.fetch(match[:name].downcase, match[0])
          end
        end
      end

      # The page's own icons, then the standard /favicon.ico; the first one
      # that actually downloads wins.
      def favicon(uri, icons)
        candidates = icons + [URI.join("#{uri.scheme}://#{uri.host}:#{uri.port}", 'favicon.ico').to_s]

        candidates.filter_map { |candidate| Image.build(candidate, uri) }
          .find { |image| fetched?(image) }
      end

      def fetched?(image)
        image.fetch
        true
      rescue Image::ImageError
        false
      end
  end
end
