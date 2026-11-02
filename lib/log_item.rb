# frozen_string_literal: true

require 'adwaita'

# LogItem is one line of the scraping log: a level and the text to show.
#
# Ported from upstream's src/models/log_item.rs, a GObject with `text` as a
# real property and `level` kept beside it in the private struct. The port
# registers the same property so the item can live in a Gio::ListStore and be
# read back by a list factory.
class LogItem < GLib::Object
  # The four levels upstream's src/backend/log.rs declares, in the order it
  # declares them. Debug is the default.
  DEBUG   = :debug
  INFO    = :info
  WARNING = :warning
  ERROR   = :error

  LEVELS = [DEBUG, INFO, WARNING, ERROR].freeze

  type_register

  install_property(
    GLib::Param::String.new(
      'text',
      'text',
      'The log line text',
      '',
      GLib::Param::READWRITE,
    ),
  )

  # GLib::Object#set_property dispatches to these accessors, so the property
  # and the Ruby attribute are the same storage.
  attr_accessor :text

  attr_reader :level

  def initialize(level = DEBUG, text = '')
    super()
    if LEVELS.include?(level)
      @level = level
    else
      @level = DEBUG
    end
    @text = text.to_s
  end
end
