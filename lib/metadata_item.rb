# frozen_string_literal: true

require 'adwaita'

# MetadataItem is one key/value pair in the metadata dialog's list.
#
# Ported from upstream's src/models/metadata_item.rs. Both fields have to be
# real GObject properties: the dialog filters the list with a
# Gtk::StringFilter over a Gtk::PropertyExpression on "key" and "value", and
# an expression can only read a registered property.
class MetadataItem < GLib::Object
  type_register

  install_property(
    GLib::Param::String.new(
      'key',
      'key',
      'The meta names and properties, joined by spaces',
      '',
      GLib::Param::READWRITE,
    ),
  )

  install_property(
    GLib::Param::String.new(
      'value',
      'value',
      'The meta content',
      '',
      GLib::Param::READWRITE,
    ),
  )

  # GLib::Object#set_property dispatches to these, so the registered
  # properties and the Ruby attributes share one storage.
  attr_accessor :key, :value

  def initialize(key = '', value = '')
    super()
    @key = key.to_s
    @value = value.to_s
  end
end
