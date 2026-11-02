# frozen_string_literal: true

require 'adwaita'

# MetadataRow is one row of the metadata dialog's list: the meta names above
# the content, both selectable.
#
# Ported from upstream's data/resources/ui/metadata-item.ui, the row the data
# dialog instantiates per list item. Upstream hides the key label for the body
# images list, where a row carries only a url, which is why the key is passed
# as nil there.
class MetadataRow
  def initialize(key, value)
    @key = key
    @value = value
  end

  def build
    row.tap do |list_row|
      list_row.child = box

      box.tap do |outer|
        outer.append(text_box)

        text_box.tap do |text|
          text.append(key_label)
          text.append(value_label)
        end
      end

      apply
    end
  end

  def row
    @row ||= Gtk::ListBoxRow.new.tap do |list_row|
      list_row.add_css_class('metadata-item')
    end
  end

  def box = @box ||= Gtk::Box.new(:horizontal, 6)

  def text_box
    @text_box ||= Gtk::Box.new(:vertical, 3).tap do |box|
      box.hexpand = true
      box.valign = :center
    end
  end

  def key_label
    @key_label ||= Gtk::Label.new.tap do |label|
      label.xalign = 0
      label.wrap = true
      label.wrap_mode = :word_char
      label.selectable = true
      label.add_css_class('caption-heading')
      label.add_css_class('dimmed-label')
    end
  end

  def value_label
    @value_label ||= Gtk::Label.new.tap do |label|
      label.xalign = 0
      label.wrap = true
      label.wrap_mode = :word_char
      label.selectable = true
    end
  end

  private

    # A nil key or value hides its label, as upstream's match arms do.
    def apply
      case @key
      when nil then key_label.visible = false
      else key_label.label = @key
      end

      case @value
      when nil then value_label.visible = false
      else value_label.label = @value
      end
    end
end
