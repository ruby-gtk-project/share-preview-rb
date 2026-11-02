# frozen_string_literal: true

require 'adwaita'

require_relative 'log_item'

# LogModel is the scraping log: the list the log dialog shows and the sink the
# card builder writes to while it works.
#
# Ported from upstream's src/models/log_model.rs (the `LogListModel`
# Gio::ListModel with `append`, `clear` and `worrying_count`) together with
# src/backend/log.rs (the `Log` trait's `log` and `flush`, which
# `LogListModel` implements). Upstream subclasses Gio::ListModel directly;
# the Ruby bindings cannot implement that interface from Ruby, so the port
# keeps a Gio::ListStore — itself a Gio::ListModel — and exposes it as
# `#model` for the list box to bind to.
class LogModel
  attr_reader :model

  def initialize
    @model = Gio::ListStore.new(LogItem.gtype)
    @main_thread = Thread.current
  end

  # The card builder runs its fetches off the main thread, so an append from
  # another thread is handed back to the main loop rather than touching the
  # list — and therefore the widgets bound to it — from under GTK.
  def append(item)
    case Thread.current
    when @main_thread then @model.append(item)
    else
      GLib::Idle.add do
        @model.append(item)
        false
      end
    end
  end

  def clear = @model.remove_all

  def n_items = @model.n_items

  def items = Array.new(@model.n_items) { |index| @model.get_item(index) }

  # Appends a line. This is upstream's `Log::log`.
  def log(level, text) = append(LogItem.new(level, text))

  # Empties the log. This is upstream's `Log::flush`.
  def flush = clear

  # The counts the window's three badges show, as [info, warning, error].
  # Debug lines are not counted, exactly as upstream's `_ => ()` arm skips
  # them.
  def worrying_count
    counts = {LogItem::INFO => 0, LogItem::WARNING => 0, LogItem::ERROR => 0}
    items.each do |item|
      if counts.key?(item.level)
        counts[item.level] += 1
      end
    end
    counts.values
  end

  # Runs the block whenever the list changes, so the badges can be refreshed.
  def on_changed(&block)
    @model.signal_connect('items-changed') { |*| block.call(worrying_count) }
  end
end
