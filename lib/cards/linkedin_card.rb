# frozen_string_literal: true

require 'adwaita'

require_relative '../card'
require_relative '../card_image'

module Cards
  # LinkedInCard is the preview LinkedIn renders: the image above a two-line
  # title and a small site line.
  #
  # Ported from upstream's data/resources/ui/cards/linkedin.ui, together with
  # the `Social::LinkedIn` arm of `CardBox::set_card` in src/widgets/card.rs,
  # which only reveals the image. LinkedIn never shows the description in the
  # card — the backend looks it up solely to warn about it.
  class LinkedinCard
    def initialize(card)
      @card = card
    end

    def build
      root.tap do |box|
        box.append(image.build)
        box.append(textbox)

        textbox.tap do |text|
          text.append(title_label)
          text.append(site_label)
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

    def site_label
      @site_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
        label.add_css_class('dim-label')
        label.add_css_class('caption')
      end
    end

    def description_label
      @description_label ||= Gtk::Label.new.tap do |label|
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
      end
  end
end
