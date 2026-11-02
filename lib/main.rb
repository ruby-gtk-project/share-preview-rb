# frozen_string_literal: true

require 'adwaita'

require_relative 'about_dialog'
require_relative 'i18n'
require_relative 'settings'
require_relative 'style'
require_relative 'window'
require_relative 'share/preview/rb/version'

# App is the application: the actions, the accelerators, the command line and
# the window group every window joins.
#
# Ported from upstream's src/application.rs and src/main.rs. The locale setup
# those two files open with — setlocale, bindtextdomain, textdomain and the
# translated application name — is in lib/i18n.rb, which binds the domain as it
# loads, so APPLICATION_NAME below is translated by the time this class body
# runs.
class App
  APP_ID = 'org.rubygtkproject.SharePreview'
  APPLICATION_NAME = _('Share Preview')
  PRGNAME = 'share-preview'
  VERSION = Share::Preview::Rb::VERSION

  # Upstream's setup_gactions and setup_accels.
  APP_ACTIONS = {
    'quit'       => ['<primary>q'],
    'about'      => [],
    'new-window' => ['<primary>n'],
  }.freeze

  WINDOW_ACCELS = {
    'win.url'               => ['<primary>l'],
    'win.show-help-overlay' => ['<primary>question'],
  }.freeze

  def initialize(app_id: APP_ID, settings: nil, present: true)
    @app_id = app_id
    @settings = settings || Settings.new
    @present = present
    @windows = []
  end

  def build
    app.tap do |application|
      application.signal_connect('startup') { on_startup }
      application.signal_connect('activate') { on_activate }
      application.signal_connect('command-line') { |_, command_line| on_command_line(command_line) }

      add_main_options
      install_actions
      install_accels
    end
  end

  def run(argv = ARGV) = app.run([PRGNAME, *argv])

  # Opens a new window, registers it with the group and returns it.
  def create_window
    Window.new(app, settings: @settings, application_icon: @app_id).tap do |window|
      window.build
      window_group.add_window(window.root)
      @windows.push(window)
    end
  end

  def app
    @app ||= Gtk::Application.new(@app_id, :handles_command_line).tap do
      GLib.application_name = APPLICATION_NAME
      GLib.prgname = PRGNAME
    end
  end

  def window_group = @window_group ||= Gtk::WindowGroup.new

  # Quits the application. This is what the app.quit action does, exposed so a
  # drive script can end the run it started.
  def quit_now = app.quit

  private

    def on_startup
      Style.install
      Gtk::Window.set_default_icon_name(@app_id)
    end

    # Upstream presents the existing window when there is one rather than
    # opening a second.
    def on_activate
      active_window.then do |window|
        case window
        when nil then show(create_window)
        else show(window)
        end
      end
    end

    # `--new-window` / `-w` always opens a fresh window; a bare URI argument
    # opens one window per uri and scrapes each.
    def on_command_line(command_line)
      uris = command_line.arguments.drop(1).reject { |argument| argument.start_with?('-') }

      case uris
      when [] then open_blank(new_window_requested?(command_line))
      else open_uris(uris, new_window_requested?(command_line))
      end

      0
    end

    def new_window_requested?(command_line)
      command_line.options_dict.contains?('new-window')
    end

    def open_blank(new_window)
      case new_window
      when true then show(create_window)
      else on_activate
      end
    end

    def open_uris(uris, new_window)
      uris.each_with_index do |uri, index|
        window_for(new_window, index).tap do |window|
          show(window)
          window.open_uri(uri)
        end
      end
    end

    # The first uri reuses the active window unless a new one was asked for.
    def window_for(new_window, index)
      case [active_window, new_window, index]
      in [Window => window, false, 0] then window
      else create_window
      end
    end

    def active_window = @windows.last

    # Tests build the whole widget tree without ever mapping a window, so a
    # run does not flash windows onto the user's desktop.
    def show(window)
      if @present
        window.present
      end
    end

    def add_main_options
      app.add_main_option(
        'new-window',
        'w'.ord,
        :none,
        :none,
        'Always open a new window for opening specified URIs',
        nil,
      )
    end

    def install_actions
      APP_ACTIONS.each_key do |name|
        Gio::SimpleAction.new(name).tap do |action|
          action.signal_connect('activate') { activate_action(name) }
          app.add_action(action)
        end
      end
    end

    def activate_action(name)
      case name
      when 'quit' then app.quit
      when 'about' then show_about
      when 'new-window' then show(create_window)
      end
    end

    def install_accels
      APP_ACTIONS.each do |name, accels|
        app.set_accels_for_action("app.#{name}", accels)
      end

      WINDOW_ACCELS.each do |name, accels|
        app.set_accels_for_action(name, accels)
      end
    end

    def show_about
      AboutDialog.new(application_icon: @app_id, version: VERSION)
        .present(active_window&.root)
    end
end
