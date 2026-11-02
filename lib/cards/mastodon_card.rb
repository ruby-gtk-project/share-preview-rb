# frozen_string_literal: true

require 'adwaita'

require_relative '../card'
require_relative '../card_image'

module Cards
  # MastodonCard is the preview Mastodon renders: the image above the site
  # line, title and description.
  #
  # Ported from upstream's data/resources/ui/cards/mastodon.ui, together with
  # the `Social::Mastodon` arm of `CardBox::set_card` in src/widgets/card.rs.
  # Mastodon is the one layout whose image is visible from the start, because
  # without an image it renders the fallback icon rather than nothing; a
  # medium-sized image turns the card sideways.
  class MastodonCard
    def initialize(card)
      @card = card
    end

    def build
      root.tap do |box|
        box.append(image.build)
        box.append(textbox)

        textbox.tap do |text|
          text.append(site_label)
          text.append(title_label)
          text.append(description_label)
        end

        apply
      end
    end

    def root = @root ||= Gtk::Box.new(:vertical, 0)

    def image = @image ||= CardImage.new

    def textbox
      @textbox ||= Gtk::Box.new(:vertical, 6).tap do |box|
        box.valign = :center
        box.add_css_class('card-padding')
      end
    end

    def site_label
      @site_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
      end
    end

    def title_label
      @title_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
        label.ellipsize = :end
        label.add_css_class('title-4')
      end
    end

    def description_label
      @description_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
        label.ellipsize = :end
        label.visible = false
      end
    end

    private

      def apply
        site_label.label = @card.site
        title_label.label = @card.title

        if @card.description
          description_label.label = @card.description
          description_label.visible = true
        end

        case @card.image
        when nil then image.set_fallback(@card.size)
        else image.set_image(@card.image, @card.size)
        end

        if @card.size == CardSize::MEDIUM
          root.orientation = :horizontal
        end
      end
  end
end
