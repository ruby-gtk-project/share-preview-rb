# frozen_string_literal: true

require 'adwaita'

# ShortcutsWindow lists the keyboard shortcuts.
#
# Ported from upstream's data/resources/ui/shortcuts.ui: one section with a
# single "General" group holding three shortcuts, all marked with the
# "shortcut window" message context.
#
# Upstream's template is a GtkShortcutsWindow. Gtk::ShortcutsWindow cannot be
# constructed from Ruby — `Gtk::ShortcutsWindow.new` raises "GtkWindow is not
# subtype of GtkShortcutsWindow" — and GTK 4.22 deprecates it in favour of
# Adw.ShortcutsDialog, which is what the port builds and what the pilot port
# uses too.
class ShortcutsWindow
  GROUP = 'General'

  # Title and accelerator per shortcut, in upstream's order. The
  # accelerators are the ones the application binds.
  SHORTCUTS = [
    ['Focus the URL entry', '<primary>l'],
    ['Show Shortcuts', '<primary>question'],
    ['Quit', '<primary>q'],
  ].freeze

  def build
    dialog.tap do |window|
      window.add(section)

      section.tap do |group|
        SHORTCUTS.each { |title, accelerator| group.add(item(title, accelerator)) }
      end
    end
  end

  def present(parent) = build.present(parent)

  def dialog
    @dialog ||= Adwaita::ShortcutsDialog.new.tap do |window|
      window.title = 'Keyboard Shortcuts'
    end
  end

  def section
    @section ||= Adwaita::ShortcutsSection.new.tap do |group|
      group.title = GROUP
    end
  end

  private

  # Positional, not keyword, arguments — the signatures the error from a
  # no-argument new advertises are not accepted as keywords.
    def item(title, accelerator) = Adwaita::ShortcutsItem.new(title, accelerator)
end
