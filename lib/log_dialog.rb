# frozen_string_literal: true

require 'adwaita'

require_relative 'log_row'

# LogDialog shows the scraping log the card builder wrote.
#
# Ported from upstream's src/widgets/log_dialog.rs and its template
# data/resources/ui/log-dialog.ui: an Adw.Dialog sized 500×500, titled
# "Scraping Log", whose scrolled list is bound to the log model. The one
# Gtk::SizeGroup is shared by every row so the level column lines up.
class LogDialog
  CONTENT_WIDTH = 500
  CONTENT_HEIGHT = 500

  def initialize(model)
    @model = model
  end

  def build
    dialog.tap do |window|
      window.child = toolbar_view

      toolbar_view.tap do |view|
        view.add_top_bar(header_bar)
        view.content = scrolled_window

        scrolled_window.tap do |scroller|
          scroller.child = list
        end
      end

      list.bind_model(@model) do |item|
        LogRow.new(item, size_group).build
      end
    end
  end

  # Upstream presents the dialog against the window it was opened from.
  def present(parent) = build.present(parent)

  def dialog
    @dialog ||= Adwaita::Dialog.new.tap do |window|
      window.title = 'Scraping Log'
      window.content_width = CONTENT_WIDTH
      window.content_height = CONTENT_HEIGHT
    end
  end

  def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new

  def header_bar = @header_bar ||= Adwaita::HeaderBar.new

  def scrolled_window
    @scrolled_window ||= Gtk::ScrolledWindow.new.tap do |scroller|
      scroller.vexpand = true
    end
  end

  def list
    @list ||= Gtk::ListBox.new.tap do |box|
      box.selection_mode = :none
      box.add_css_class('logs')
      box.add_css_class('background')
    end
  end

  def size_group = @size_group ||= Gtk::SizeGroup.new(:horizontal)
end
