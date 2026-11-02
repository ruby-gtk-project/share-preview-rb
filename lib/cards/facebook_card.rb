# frozen_string_literal: true

require 'adwaita'

require_relative '../card'
require_relative '../card_image'

module Cards
  # FacebookCard is the preview Facebook renders: the image above an
  # upper-cased site line, a two-line title and a one-line description.
  #
  # Ported from upstream's data/resources/ui/cards/facebook.ui, together with
  # the `Social::Facebook` arm of `CardBox::set_card` in src/widgets/card.rs:
  # the description only appears when the title is at most 65 characters, and
  # a medium-sized image turns the card sideways.
  class FacebookCard
    # Facebook truncates the description away behind a long title.
    TITLE_LIMIT = 65

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

    def image
      @image ||= CardImage.new.tap do |card_image|
        card_image.visible = false
      end
    end

    def textbox
      @textbox ||= Gtk::Box.new(:vertical, 6).tap do |box|
        box.add_css_class('card-padding')
      end
    end

    def site_label
      @site_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
        label.add_css_class('dim-label')
      end
    end

    def title_label
      @title_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
        label.ellipsize = :end
        label.wrap = true
        label.lines = 2
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
        end

        if @card.image
          image.set_image(@card.image, @card.size)
          image.visible = true
        end

        if @card.description && @card.title.length <= TITLE_LIMIT
          description_label.visible = true
        end

        if @card.size == CardSize::MEDIUM
          root.orientation = :horizontal
        end
      end
  end
end
