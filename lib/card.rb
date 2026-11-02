# frozen_string_literal: true

require_relative 'i18n'
require_relative 'image'
require_relative 'log_item'
require_relative 'social'

# CardSize is the shape a card is rendered at, and the pixel sizes that shape
# asks its image and its fallback icon for.
#
# Ported from upstream's `CardSize` enum in src/backend/card.rs. Upstream maps
# a `SocialImageSizeKind` onto it with `from_social`; the port spells both
# enums with the same three symbols, so that mapping is the identity.
module CardSize
  SMALL  = :small
  MEDIUM = :medium
  LARGE  = :large

  IMAGE_SIZES = {
    SMALL  => [64, 64],
    MEDIUM => [125, 125],
    LARGE  => [500, 250],
  }.freeze

  ICON_SIZES = {
    SMALL  => 32,
    MEDIUM => 48,
    LARGE  => 64,
  }.freeze

  class << self
    def from_social(kind)
      case IMAGE_SIZES.key?(kind)
      when true then kind
      else SMALL
      end
    end

    def image_size(size) = IMAGE_SIZES.fetch(size, IMAGE_SIZES[SMALL])

    def icon_size(size) = ICON_SIZES.fetch(size, ICON_SIZES[SMALL])
  end
end

# Raised when a platform's card cannot be built from the scraped data.
#
# Ported from upstream's `CardError` enum: the two variants, and the names its
# Display impl writes.
class CardError < StandardError
  NOT_ENOUGH_DATA       = :not_enough_data
  TWITTER_NO_CARD_FOUND = :twitter_no_card_found

  attr_reader :kind

  def initialize(kind)
    super(kind.to_s.split('_').map(&:capitalize).join)
    @kind = kind
  end
end

# Card is the preview one platform would render for one page: the resolved
# title, site, description, favicon bytes, thumbnailed image bytes and the
# size the image settled at.
#
# Ported from upstream's `Card` struct and its `new`, `lookup_image`,
# `get_ideal_image` and `thumbnail_image` methods in src/backend/card.rs.
# Building a card is also what writes the scraping log, so every lookup and
# every rejected image goes to the logger passed in.
class Card
  attr_reader :title, :site, :favicon, :description, :image, :size, :social

  def initialize(data, social, logger)
    @data = data
    @social = social
    @logger = logger
    @lookups = social.lookups
    @constraints = social.constraints
    @site = data.url.to_s
    @size = CardSize::SMALL
    @image = nil
    @image_sizes = []

    @favicon = fetch_favicon
    prepare
    @title = resolve_title
    @description = resolve_description
    check_card_type
    check_enough_data
    resolve_image
  end

  private

    # Upstream fetches the favicon first and ignores any failure.
    def fetch_favicon
      @data.favicon&.fetch
    rescue Image::ImageError
      nil
    end

    # The per-platform preparation upstream does before any lookup: which
    # image shapes the platform will accept, and where its site line comes
    # from.
    def prepare
      case @social.key
      when :facebook
        @image_sizes = [Social::LARGE, Social::MEDIUM]
        @site = @site.upcase
      when :linkedin
        @image_sizes = [Social::LARGE]
      when :mastodon
        @image_sizes = [Social::LARGE, Social::MEDIUM]
        prepare_site_name
      when :discourse
        @image_sizes = [Social::SMALL]
        prepare_site_name
      end
    end

    # Mastodon and Discourse show og:site_name instead of the host.
    def prepare_site_name
      value = @data.lookup_meta(['og:site_name'])

      case value
      when nil then nil
      when ''
        warn_social(f_('"{name}" is empty!', name: 'og:site_name'))
      else
        @site = value
        log_social(LogItem::INFO, f_('Found "{name}".', name: 'og:site_name'))
      end
    end

    def resolve_title
      @pre_title = @data.lookup_meta(@lookups[:title], @logger)

      case [@pre_title, @data.title]
      in [String => title, _] then title
      in [nil, String => document_title]
        warn_social(_('Unable to find a metadata for title!. Falling back to document title.'))
        document_title
      else
        warn_social(_('Unable to find a metadata for title!. Falling back to document title.'))
        warn_social(_('Unable to find the document title!. Falling back to site url.'))
        @site
      end
    end

    # LinkedIn is the one platform upstream nags about the description.
    def resolve_description
      @data.lookup_meta(@lookups[:description], @logger).tap do |description|
        describe(description)
      end
    end

    def describe(description)
      case [@social.key, description]
      in [:linkedin, nil]
        warn_social(
          f_(
            'Add a "{tag}" tag to the page to have control over the content.',
            tag: 'og:description',
          ),
        )
      in [:linkedin, String => text] if text.length < 100
        warn_social(
          f_(
            'The description should be at least "{count}" characters long.',
            count: '100',
          ),
        )
      else
        nil
      end
    end

    # Twitter needs a card type: its absence is fatal, and a "twitter:card" of
    # summary_large_image upgrades the image shapes it will accept.
    def check_card_type
      card_type = @data.lookup_meta(@lookups[:kind], @logger)

      if @social == Social::TWITTER
        case card_type
        when nil
          log_social(LogItem::ERROR, _('Unable to find any valid card type.'))
          raise CardError, CardError::TWITTER_NO_CARD_FOUND
        else
          note_twitter_card
          @image_sizes.push(Social::MEDIUM)
        end
      end
    end

    def note_twitter_card
      value = @data.lookup_meta(['twitter:card'])

      case value
      when nil
        warn_social(
          f_(
            'Unable to find "{name}". Consider providing a "{name}" meta property.',
            name: 'twitter:card',
          ),
        )
      else
        if value == 'summary_large_image'
          @image_sizes.push(Social::LARGE)
        end
        log_social(LogItem::INFO, f_('Found card of type "{name}".', name: value))
      end
    end

    # A Twitter card with neither a title meta nor a description is not a card
    # at all.
    def check_enough_data
      if @social == Social::TWITTER && @pre_title.nil? && @description.nil?
        log_social(LogItem::ERROR, _('Unable to find any valid title or description.'))
        raise CardError, CardError::NOT_ENOUGH_DATA
      end
    end

    def resolve_image
      found = lookup_image(meta_images, body_images)

      case found
      when nil then warn_no_image
      else
        @image = found[:bytes]
        @size = found[:size]
      end
    end

    def meta_images = @data.lookup_meta_images(@lookups[:image])

    # Only the two platforms that fall back to the document body get its
    # images.
    def body_images
      case @social.key
      when :linkedin, :facebook then @data.get_body_images(5)
      end
    end

    def warn_no_image
      case @social.key
      when :discourse
        warn_social(_('Unable to find a valid image in the metadata.'))
      when :linkedin, :facebook
        warn_social(_('Unable to find a valid image in the metadata or document body.'))
      when :mastodon
        warn_social(_('Unable to find a valid image in the metadata, will render an icon.'))
      when :twitter
        warn_social(
          f_(
            'Unable to find a valid image in the metadata, will render a "{name}" card with icon.',
            name: 'summary',
          ),
        )
        @size = CardSize::MEDIUM
      end
    end

    # Prefers an image that meets a recommended size; only when the metadata
    # has none does it look at the body images, and only an ideal body image
    # beats a merely valid metadata one.
    def lookup_image(images, images_from_body)
      result = ideal_image(images, first_fit: false)
      look_body = result.nil? || !result[:ideal]

      body_result = nil
      if look_body && images_from_body
        candidate = ideal_image(images_from_body, first_fit: true)
        if candidate && candidate[:ideal]
          body_result = candidate
        end
      end

      body_result || result
    end

    # Checks every candidate, groups the usable ones by the shape they fit,
    # then picks the largest one meeting a recommended size — or the first
    # merely valid one, flagged as not ideal.
    def ideal_image(images, first_fit:)
      valid = check_images(images)

      recommended = catch(:fit) do
        @image_sizes.reduce(nil) do |best, kind|
          candidates = valid[kind]
          case candidates
          when [] then best
          else best_of(candidates, kind, first_fit: first_fit) || best
          end
        end
      end

      thumbnail_for(recommended, first_valid_of(valid))
    end

    # The first candidate of the first shape that had any, kept as the backup
    # upstream falls back to when nothing reaches a recommended size.
    def first_valid_of(valid)
      kind = @image_sizes.find { |candidate| !valid[candidate].empty? }

      case kind
      when nil then nil
      else [valid[kind].first, kind]
      end
    end

    def check_images(images)
      images.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |image, valid|
        kind = check_image(image)
        unless kind.nil?
          valid[kind].push(image)
        end
      end
    end

    # Returns the shape the image fits, or nil after logging why it does not.
    def check_image(image)
      case [@social == Social::TWITTER, image.was_relative]
      in [true, true]
        warn_plain(
          f_('Image "{url}" is defined with a relative url.', url: image.url.to_s),
        )
        nil
      else
        check_image_size(image)
      end
    end

    def check_image_size(image)
      kind = image.check(@social, @image_sizes, @constraints)
      log_plain(
        LogItem::DEBUG,
        f_('Image "{url}" met the requirements.', url: image.url.to_s),
      )
      kind
    rescue Image::ImageError => e
      log_rejected(image, e)
      nil
    end

    # The levels upstream logs each image failure at.
    def log_rejected(image, error)
      case error.kind
      when :fetch_error
        log_plain(LogItem::DEBUG, format('%{error}: "%{url}".', error: error.message, url: image.url))
      when :request_error
        log_plain(LogItem::ERROR, format('%{error}: "%{url}".', error: error.message, url: image.url))
      when :too_heavy, :unsupported
        warn_social(requirements_text(image, error))
      else
        log_social(LogItem::DEBUG, requirements_text(image, error))
      end
    end

    def requirements_text(image, error)
      f_(
        'Image "{url}" did not meet the requirements: {info}.',
        url:  image.url.to_s,
        info: error.message,
      )
    end

    # The biggest candidate of this shape that reaches the recommended size.
    def best_of(candidates, kind, first_fit:)
      width, height = @social.image_size(kind)[:recommended]
      previous = [0, 0]
      best = nil

      candidates.each do |image|
        image_width, image_height = image.size
        big_enough = image_width >= width && image_height >= height
        beats_previous = previous == [0, 0] || (image_width >= previous[0] && image_height >= previous[1])

        if big_enough && beats_previous
          previous = [image_width, image_height]
          best = [image, kind]
          if first_fit
            throw(:fit, best)
          end
        end
      end

      best
    end

    # Upstream only falls back to the first valid image when nothing met a
    # recommended size; a recommended image that fails to thumbnail yields
    # nothing rather than demoting to the fallback.
    def thumbnail_for(recommended, first_valid)
      case [recommended, first_valid]
      in [[image, kind], _] then thumbnail_image(image, kind, ideal: true)
      in [nil, [image, kind]] then thumbnail_image(image, kind, ideal: false)
      else nil
      end
    end

    def thumbnail_image(image, kind, ideal:)
      size = CardSize.from_social(kind)
      width, height = CardSize.image_size(size)
      bytes = image.thumbnail(width, height)
      log_plain(
        LogItem::DEBUG,
        f_('Image "{url}" processed successfully.', url: image.url.to_s),
      )
      {bytes: bytes, size: size, ideal: ideal}
    rescue Image::ImageError => e
      log_plain(
        LogItem::DEBUG,
        f_(
          'Failed to thumbnail "{url}": {info}.',
          url:  image.url.to_s,
          info: e.message,
        ),
      )
      nil
    end

    # Most of the card builder's lines are prefixed with the platform name.
    def log_social(level, text) = @logger.log(level, "#{@social}: #{text}")

    def warn_social(text) = log_social(LogItem::WARNING, text)

    def log_plain(level, text) = @logger.log(level, text)

    def warn_plain(text) = log_plain(LogItem::WARNING, text)
end
