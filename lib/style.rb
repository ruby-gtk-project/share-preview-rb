# frozen_string_literal: true

require 'adwaita'

# Style installs the app's stylesheet and its bundled icons.
#
# Ported from upstream's data/resources/style.css and the gresource that
# carries it, plus data/resources/icons, the three symbolic icons upstream
# bundles because they are not in the system icon theme: code-symbolic (the
# "View Metadata" button), info-symbolic (the info count badge) and
# tag-symbolic (the metadata dialog's page). Upstream registers both through
# its compiled gresource; the port loads the stylesheet from data/style.css
# and points the icon theme at data/icons, where the icons sit in the theme
# layout GTK expects.
module Style
  DATA_DIR = File.expand_path('../data', __dir__)
  STYLESHEET = File.join(DATA_DIR, 'style.css')
  ICONS_DIR = File.join(DATA_DIR, 'icons')
  PRIORITY = Gtk::StyleProvider::PRIORITY_APPLICATION

  class << self
    # Call once the display exists — that is, from the application's startup
    # or activate handler.
    def install
      Gdk::Display.default.then do |display|
        if display
          add_stylesheet(display)
          add_icons(display)
        end
      end
    end

    private

      def add_stylesheet(display)
        Gtk::StyleContext.add_provider_for_display(display, provider, PRIORITY)
      end

      def provider
        Gtk::CssProvider.new.tap do |css|
          css.load(path: STYLESHEET)
        end
      end

      def add_icons(display)
        Gtk::IconTheme.get_for_display(display).add_search_path(ICONS_DIR)
      end
  end
end
