# frozen_string_literal: true

require_relative 'card'
require_relative 'i18n'
require_relative 'log_item'

# Meta is one meta tag found in the page.
#
# Ported from upstream's `Meta` struct in src/backend/data.rs: the tag's
# `name` attribute, every value of its `property` attribute, its `content`,
# and the Image that content parses to when the tag is an image tag.
Meta = Struct.new(
  :name,
  :property,
  :content,
  :image,
  keyword_init: true,
) do
  def property = self[:property] || []
end

# PageData is everything scraped from one page, and the lookups the card
# builder runs over it.
#
# Ported from upstream's `Data` struct in src/backend/data.rs, with
# `get_meta`, `get_meta_image`, `lookup_meta`, `lookup_meta_images` and
# `get_body_images`. The name gains its prefix because Ruby 3.2 made `Data` a
# core class, and reopening that one breaks `new`.
class PageData
  attr_accessor :url, :title, :favicon
  attr_reader :metadata, :body_images

  def initialize(url: '', title: nil, favicon: nil, metadata: [], body_images: [])
    @url = url
    @title = title
    @favicon = favicon
    @metadata = metadata
    @body_images = body_images
  end

  # Every meta whose property list contains the name, or whose name attribute
  # is the name.
  def get_meta(name)
    @metadata.select do |meta|
      meta.property.include?(name) || meta.name == name
    end
  end

  # The same lookup, but yielding only the images those metas parsed to.
  def get_meta_image(name) = get_meta(name).filter_map(&:image)

  # The first non-empty content among the given meta names, logging the way
  # upstream does: a debug line per name tried, a warning for a name that is
  # present but empty.
  def lookup_meta(lookup, logger = nil)
    found = nil

    lookup.each do |name|
      content = get_meta(name).first&.content

      case content
      when nil
        log(logger, LogItem::DEBUG, f_('No occurrences found for "{name}"!', name: name))
      when ''
        log(logger, LogItem::WARNING, f_('"{name}" is empty!', name: name))
      else
        log(
          logger,
          LogItem::DEBUG,
          f_(
            'Found a valid occurrence for "{name}" with value "{value}".',
            name:  name,
            value: content,
          ),
        )
        found = content
      end

      unless found.nil?
        break
      end
    end

    found
  end

  # Every image behind the given meta names, in lookup order. Unlike
  # #lookup_meta this logs nothing, as upstream notes.
  def lookup_meta_images(lookup) = lookup.flat_map { |name| get_meta_image(name) }

  # The images found in the document body, truncated so a page full of them
  # cannot stall the card.
  def get_body_images(length) = @body_images.first(length)

  # Builds the card for one platform. This is upstream's `Data::get_card`.
  def get_card(social, logger) = Card.new(self, social, logger)

  private

    def log(logger, level, text)
      if logger
        logger.log(level, text)
      end
    end
end
