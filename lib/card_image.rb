# frozen_string_literal: true

require 'adwaita'
require 'gdk_pixbuf2'

require_relative 'card'

# CardImage shows a card's image, or a dimmed document icon when there is no
# usable image to show.
#
# Ported from upstream's src/widgets/image.rs and its template
# data/resources/ui/image.ui: a box holding a crossfading stack with a
# "fallback" page (a centred symbolic icon) and an "image" page (a
# GtkPicture), plus `set_image` and `set_fallback`, which size the page they
# switch to from the card's size.
class CardImage
  FALLBACK = 'fallback'
  IMAGE = 'image'

  def build
    root.tap do |box|
      box.append(stack)

      stack.tap do |pages|
        pages.add_named(fallback_box, FALLBACK)
        pages.add_named(image_box, IMAGE)

        fallback_box.tap do |fallback|
          fallback.append(fallback_icon)
        end

        image_box.tap do |images|
          images.append(picture)
        end
      end
    end
  end

  # Shows the image at the size the card settled at, falling back to the icon
  # when the bytes will not decode.
  def set_image(bytes, size)
    width, height = CardSize.image_size(size)
    picture.width_request = width
    picture.height_request = height

    texture(bytes).then do |paintable|
      case paintable
      when nil then set_fallback(size)
      else
        picture.paintable = paintable
        stack.visible_child_name = IMAGE
      end
    end
  end

  # Shows the icon, in a box the size the image would have taken.
  def set_fallback(size)
    width, height = CardSize.image_size(size)
    fallback_box.width_request = width
    fallback_box.height_request = height
    fallback_icon.pixel_size = CardSize.icon_size(size)
    stack.visible_child_name = FALLBACK
  end

  def visible=(value)
    root.visible = value
  end

  def root = @root ||= Gtk::Box.new(:horizontal, 0)

  def stack
    @stack ||= Gtk::Stack.new.tap do |pages|
      pages.transition_type = :crossfade
    end
  end

  def fallback_box
    @fallback_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.hexpand_set = true
    end
  end

  def fallback_icon
    @fallback_icon ||= Gtk::Image.new.tap do |icon|
      icon.icon_name = 'x-office-document-symbolic'
      icon.hexpand = true
      icon.halign = :center
      icon.add_css_class('dim-label')
    end
  end

  def image_box = @image_box ||= Gtk::Box.new(:horizontal, 0)

  def picture = @picture ||= Gtk::Picture.new

  private

    def texture(bytes)
      Gdk::Texture.new(GLib::Bytes.new(bytes))
    rescue GdkPixbuf::PixbufError, GLib::Error, TypeError
      nil
    end
end
