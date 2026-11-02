# frozen_string_literal: true

require 'adwaita'

require_relative '../card'
require_relative '../card_image'

module Cards
  # TwitterCard is the preview Twitter renders: the image above the title,
  # description and site line.
  #
  # Ported from upstream's data/resources/ui/cards/twitter.ui, together with
  # the `Social::Twitter` arm of `CardBox::set_card` in src/widgets/card.rs: a
  # medium-sized image turns the card sideways and clamps the description to
  # three lines, a large one clamps it to two.
  class TwitterCard
    MEDIUM_LINES = 3
    LARGE_LINES = 2

    def initialize(card)
      @card = card
    end

    def build
      root.tap do |box|
        box.append(image.build)
        box.append(textbox)

        textbox.tap do |text|
          text.append(title_label)
          text.append(description_label)
          text.append(site_label)
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

    def title_label
      @title_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
        label.ellipsize = :end
        label.add_css_class('heading')
      end
    end

    def description_label
      @description_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
        label.ellipsize = :end
        label.wrap = true
        label.visible = false
      end
    end

    def site_label
      @site_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
        label.add_css_class('dim-label')
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

        if @card.image
          image.set_image(@card.image, @card.size)
          image.visible = true
        end

        clamp_description
      end

      def clamp_description
        case @card.size
        when CardSize::MEDIUM
          root.orientation = :horizontal
          description_label.lines = MEDIUM_LINES
        when CardSize::LARGE
          description_label.lines = LARGE_LINES
        end
      end
  end
end
