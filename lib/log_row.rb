# frozen_string_literal: true

require 'adwaita'

require_relative 'log_item'

# LogRow is one row of the scraping log: the level on the left, the line's
# text beside it.
#
# Ported from the `bind_model` closure in upstream's
# src/widgets/log_dialog.rs, which builds the row by hand and styles it from
# the item's level: debug is dimmed and set in the caption size, info is
# accented, warning and error take their named colours.
class LogRow
  # The label, and the CSS classes the container and labels take, per level.
  LEVELS = {
    LogItem::DEBUG   => {label: 'DEBUG', container: %w[debug dim-label], labels: %w[caption]},
    LogItem::INFO    => {label: 'INFO', container: %w[accent], labels: []},
    LogItem::WARNING => {label: 'WARNING', container: %w[warning], labels: []},
    LogItem::ERROR   => {label: 'ERROR', container: %w[error], labels: []},
  }.freeze

  def initialize(item, size_group)
    @item = item
    @size_group = size_group
  end

  def build
    row.tap do |list_row|
      list_row.child = container

      container.tap do |box|
        box.append(level_label)
        box.append(text_label)
      end

      apply
    end
  end

  def row = @row ||= Gtk::ListBoxRow.new

  def container
    @container ||= Gtk::Box.new(:horizontal, 12).tap do |box|
      box.add_css_class('log-item')
    end
  end

  def level_label
    @level_label ||= Gtk::Label.new.tap do |label|
      label.valign = :start
      label.xalign = 0
    end
  end

  def text_label
    @text_label ||= Gtk::Label.new.tap do |label|
      label.wrap = true
      label.hexpand = true
      label.xalign = 0
      label.selectable = true
    end
  end

  private

    # The size group is shared by every row in the dialog, so the level
    # column lines up down the list.
    def apply
      @size_group.add_widget(level_label)
      text_label.label = @item.text.to_s

      LEVELS.fetch(@item.level, LEVELS[LogItem::DEBUG]).then do |style|
        level_label.label = style[:label]
        style[:container].each { |name| container.add_css_class(name) }
        style[:labels].each do |name|
          level_label.add_css_class(name)
          text_label.add_css_class(name)
        end
      end
    end
end
