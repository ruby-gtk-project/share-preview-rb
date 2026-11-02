# frozen_string_literal: true

require 'adwaita'
require 'gdk_pixbuf2'

require_relative '../card'
require_relative '../card_image'

module Cards
  # DiscourseCard is the preview Discourse renders: a favicon and site line
  # above a small square image beside the title and description.
  #
  # Ported from upstream's data/resources/ui/cards/discourse.ui, together with
  # the `Social::Discourse` arm of `CardBox::set_card` in src/widgets/card.rs,
  # which reveals the image when there is one and the favicon when its bytes
  # decode. Discourse is the one layout with a favicon.
  class DiscourseCard
    def initialize(card)
      @card = card
    end

    def build
      root.tap do |box|
        box.append(header)
        box.append(body)

        header.tap do |head|
          head.append(favicon)
          head.append(site_label)
        end

        body.tap do |content|
          content.append(image.build)
          content.append(textbox)

          textbox.tap do |text|
            text.append(title_label)
            text.append(description_label)
          end
        end

        apply
      end
    end

    def root
      @root ||= Gtk::Box.new(:vertical, 12).tap do |box|
        box.add_css_class('card-padding')
      end
    end

    def header = @header ||= Gtk::Box.new(:horizontal, 6)

    def favicon
      @favicon ||= Gtk::Image.new.tap do |icon|
        icon.visible = false
      end
    end

    def site_label
      @site_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.ellipsize = :end
      end
    end

    def body = @body ||= Gtk::Box.new(:horizontal, 12)

    def image
      @image ||= CardImage.new.tap do |card_image|
        card_image.root.valign = :start
        card_image.root.halign = :start
        card_image.visible = false
      end
    end

    def textbox
      @textbox ||= Gtk::Box.new(:vertical, 12).tap do |box|
        box.width_request = 400
      end
    end

    def title_label
      @title_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.wrap = true
        label.add_css_class('title-4')
      end
    end

    def description_label
      @description_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.wrap = true
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

        show_favicon
      end

      def show_favicon
        texture(@card.favicon).then do |paintable|
          if paintable
            favicon.paintable = paintable
            favicon.visible = true
          end
        end
      end

      def texture(bytes)
        case bytes
        when nil then nil
        else Gdk::Texture.new(GLib::Bytes.new(bytes))
        end
      rescue GdkPixbuf::PixbufError, GLib::Error, TypeError
        nil
      end
  end
end
