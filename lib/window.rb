# frozen_string_literal: true

require 'uri'

require 'adwaita'

require_relative 'card'
require_relative 'card_box'
require_relative 'data'
require_relative 'i18n'
require_relative 'data_dialog'
require_relative 'log_dialog'
require_relative 'log_item'
require_relative 'log_model'
require_relative 'scraper'
require_relative 'settings'
require_relative 'shortcuts_window'
require_relative 'social'

# Window is the app's main window: the url box, the platform drop-down and
# the stack that shows the splash, the spinner, an error or the card.
#
# Ported from upstream's src/window.rs and its template
# data/resources/ui/window.ui, including the primary menu that template
# declares. The four window actions are upstream's: win.run scrapes the url,
# win.metadata and win.log open the dialogs, win.url focuses the entry.
class Window
  DEFAULT_WIDTH = 524
  DEFAULT_HEIGHT = 562

  SPLASH = 'splash'
  LOADING = 'loading'
  ERROR = 'error'
  CARD = 'card'

  # The two error states upstream's run() renders for a Scraper::Error.
  NETWORK_TITLE = _('Network Error')
  UNEXPECTED_TITLE = _('Unexpected Error')
  CONNECTION_MESSAGE = _('Couldn’t connect to the given URL.')

  # Mirrors upstream's `klass.install_action` calls, plus the
  # show-help-overlay action a GtkApplicationWindow gives upstream for free.
  ACTIONS = ['run', 'metadata', 'log', 'url', 'show-help-overlay'].freeze

  attr_reader :logger

  def initialize(app, settings: nil, application_icon: nil)
    @app = app
    @settings = settings || Settings.new
    @application_icon = application_icon
    @logger = LogModel.new
    @data = PageData.new
    @active_url = ''
    @card = nil
  end

  def build
    window.tap do |win|
      win.content = window_handle

      window_handle.tap do |handle|
        handle.child = toasts

        toasts.tap do |overlay|
          overlay.child = toolbar_view

          toolbar_view.tap do |view|
            view.add_top_bar(header_bar)
            view.add_top_bar(url_box)
            view.content = stack

            header_bar.tap do |bar|
              bar.pack_start(color_scheme)
              bar.pack_end(menu_button)

              color_scheme.signal_connect('clicked') { toggle_color_scheme }
            end

            url_box.tap do |box|
              box.append(social)
              box.append(url_entry)

              social.signal_connect('notify::selected') { on_social_selected }

              url_entry.tap do |entry|
                entry.signal_connect('changed') { on_url_entry_changed }
                entry.signal_connect('activate') { run }
                entry.signal_connect('icon-press') { |_, position| on_icon_press(position) }
              end
            end

            stack.tap do |pages|
              pages.add_named(start_page, SPLASH)
              pages.add_named(loading_box, LOADING)
              pages.add_named(error_box, ERROR)
              pages.add_named(card_container, CARD)

              loading_box.tap do |loading|
                loading.append(spinner)
              end

              error_box.tap do |errors|
                errors.append(error_title)
                errors.append(error_message)
              end

              card_container.tap do |container|
                container.append(buttons)

                buttons.tap do |center|
                  center.center_widget = metadata_button
                  center.end_widget = log_button

                  log_button.tap do |button|
                    button.child = counts_box

                    counts_box.tap do |counts|
                      counts.append(inf_count)
                      counts.append(war_count)
                      counts.append(err_count)
                    end
                  end
                end
              end
            end
          end
        end
      end

      install_actions
      setup_widgets
      win.set_focus(url_entry)
    end
  end

  def present = window.present

  # The Gtk window itself: the application's window group adds it, and the
  # dialogs are presented against it.
  def root = window

  # Fills the entry with a uri and scrapes it, as upstream's open_uri does.
  def open_uri(uri)
    url_entry.text = uri.to_s
    run
  end

  private

    def setup_widgets
      if @application_icon
        start_page.icon_name = @application_icon
      end

      social.selected = Social.from_s(@settings.social).index
      @logger.on_changed { |counts| update_counts(counts) }
      update_counts(@logger.worrying_count)
    end

    def install_actions
      ACTIONS.each do |name|
        Gio::SimpleAction.new(name).tap do |action|
          action.signal_connect('activate') { activate_action(name) }
          window.add_action(action)
        end
      end
    end

    def activate_action(name)
      case name
      when 'run' then run
      when 'metadata' then show_metadata
      when 'log' then show_log
      when 'url' then url_entry.grab_focus
      when 'show-help-overlay' then ShortcutsWindow.new.present(window)
      end
    end

    # Upstream prefixes a scheme-less url with http:// and writes the result
    # back into the entry before parsing it.
    def run
      text = url_entry.text.to_s.strip

      unless text.empty?
        url = with_scheme(text)
        url_entry.text = url
        start(url)
      end
    end

    def with_scheme(text)
      case text
      when %r{\Ahttps?://} then text
      else "http://#{text}"
      end
    end

    def start(url)
      uri = parse(url)

      case uri
      when nil
        toasts.add_toast(Adwaita::Toast.new(_('Invalid URL')))
        url_entry.add_css_class('error')
      else
        url_entry.remove_css_class('error')
        url_box.sensitive = false
        show_loading
        scrape(uri)
      end
    end

    def parse(url)
      URI.parse(url).then do |uri|
        case uri
        when URI::HTTP then uri
        end
      end
    rescue URI::InvalidURIError
      nil
    end

    # The scrape and the card build both do network work, so they run off the
    # main thread and come back through the main loop to touch any widget.
    def scrape(uri)
      Thread.new do
        result = scrape_result(uri)

        GLib::Idle.add do
          finish_scrape(uri, result)
          false
        end
      end
    end

    def scrape_result(uri)
      {data: Scraper.scrape(uri)}
    rescue Scraper::Error => e
      {error: e}
    end

    def finish_scrape(uri, result)
      case result
      in {data: PageData => data}
        @data = data
        @active_url = uri.to_s
        rebuild_card { stack.visible_child_name = CARD }
      in {error: Scraper::Error => error}
        show_error(error)
        stop_loading
      end
    end

    def show_error(error)
      title, message = error_texts(error)
      error_title.label = title
      error_message.label = message
      stack.visible_child_name = ERROR
    end

    def error_texts(error)
      case [error.kind, error.status]
      in [Scraper::Error::NETWORK_ERROR, _] then [NETWORK_TITLE, CONNECTION_MESSAGE]
      in [_, ''] then [UNEXPECTED_TITLE, CONNECTION_MESSAGE]
      else [UNEXPECTED_TITLE, f_('Server Error {status}', status: error.status)]
      end
    end

    def show_loading
      stack.visible_child_name = LOADING
      spinner.start
    end

    def stop_loading
      spinner.stop
      url_box.sensitive = true
    end

    # Rebuilds the card for the selected platform. Upstream's update_card:
    # the log is flushed first, so the card's own log is all the dialog shows.
    def rebuild_card(&after)
      @logger.flush
      social_choice = Social.at(social.selected)
      data = @data

      Thread.new do
        result = card_result(data, social_choice)

        GLib::Idle.add do
          replace_card(result)
          after&.call
          stop_loading
          false
        end
      end
    end

    def card_result(data, social_choice)
      {card: data.get_card(social_choice, @logger)}
    rescue CardError => e
      {error: e}
    end

    def replace_card(result)
      case result
      in {card: Card => card} then swap_card(CardBox.from_card(card))
      in {error: CardError => error} then swap_card(CardBox.from_error(error))
      end
    end

    def swap_card(box)
      if @card
        card_container.remove(@card.root)
      end

      @card = box
      card_container.prepend(box.root)
    end

    def show_metadata = DataDialog.new(@data).present(window)

    def show_log = LogDialog.new(@logger.model).present(window)

    def toggle_color_scheme
      Adwaita::StyleManager.default.then do |manager|
        case manager.dark?
        when true then manager.color_scheme = :force_light
        else manager.color_scheme = :force_dark
        end
      end
    end

    def on_url_entry_changed
      url_entry.set_icon_sensitive(:secondary, !url_entry.text.to_s.empty?)
    end

    def on_icon_press(position)
      case position
      when Gtk::EntryIconPosition::SECONDARY then run
      end
    end

    # Remembers the platform and, when a url has already been scraped,
    # rebuilds the card for the new one.
    def on_social_selected
      @settings.social = Social.at(social.selected).to_s

      unless @active_url.empty?
        show_loading
        rebuild_card { stack.visible_child_name = CARD }
      end
    end

    # The three badges: coloured and lit when they counted something, dimmed
    # when they did not.
    def update_counts(counts)
      [[inf_count, 'accent'], [war_count, 'warning'], [err_count, 'error']]
        .zip(counts)
        .each { |(badge, css), count| style_count(badge, css, count) }
    end

    def style_count(badge, css, count)
      case count.positive?
      when true
        badge.add_css_class(css)
        badge.remove_css_class('dim-label')
      else
        badge.add_css_class('dim-label')
        badge.remove_css_class(css)
      end

      badge.label = count.to_s
    end

  # Widgets

    def window
      @window ||= Adwaita::ApplicationWindow.new(@app).tap do |win|
        win.title = _('Share Preview')
        win.set_default_size(DEFAULT_WIDTH, DEFAULT_HEIGHT)
        win.resizable = false
      end
    end

    def window_handle = @window_handle ||= Gtk::WindowHandle.new

    def toasts = @toasts ||= Adwaita::ToastOverlay.new

    def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new

    def header_bar = @header_bar ||= Gtk::HeaderBar.new

    def color_scheme
      @color_scheme ||= Gtk::Button.new.tap do |button|
        button.icon_name = 'display-brightness-symbolic'
        button.tooltip_text = _('Toggle Color Scheme')
      end
    end

    def menu_button
      @menu_button ||= Gtk::MenuButton.new.tap do |button|
        button.menu_model = primary_menu
        button.icon_name = 'open-menu-symbolic'
        button.tooltip_text = _('Main Menu')
      end
    end

    # The primary menu upstream declares in window.ui: one item in its own
    # section, then the shortcuts and about items.
    def primary_menu
      @primary_menu ||= Gio::Menu.new.tap do |menu|
        menu.append_section(nil, window_section)
        menu.append_section(nil, help_section)
      end
    end

    def window_section
      @window_section ||= Gio::Menu.new.tap do |menu|
        menu.append(_('_New Window'), 'app.new-window')
      end
    end

    def help_section
      @help_section ||= Gio::Menu.new.tap do |menu|
        menu.append(_('_Keyboard Shortcuts'), 'win.show-help-overlay')
        menu.append(_('_About Share Preview'), 'app.about')
      end
    end

    def url_box
      @url_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
        box.hexpand = true
        box.halign = :fill
        box.add_css_class('linked')
        box.add_css_class('urlbox')
      end
    end

    def social
      @social ||= Gtk::DropDown.new(Gtk::StringList.new(Social.names)).tap do |drop_down|
        drop_down.halign = :end
        drop_down.valign = :center
      end
    end

    def url_entry
      @url_entry ||= Gtk::Entry.new.tap do |entry|
        entry.hexpand = true
        entry.input_purpose = :url
        entry.secondary_icon_name = 'go-next-symbolic'
        entry.secondary_icon_sensitive = false
        entry.secondary_icon_tooltip_text = _('Go')
      end
    end

    def stack
      @stack ||= Gtk::Stack.new.tap do |pages|
        pages.transition_type = :crossfade
        pages.hhomogeneous = true
        pages.vexpand = true
      end
    end

    def start_page
      @start_page ||= Adwaita::StatusPage.new.tap do |page|
        page.title = _('Set a URL to preview')
      end
    end

    def loading_box
      @loading_box ||= Gtk::Box.new(:horizontal, 6).tap do |box|
        box.halign = :center
        box.valign = :center
      end
    end

    def spinner
      @spinner ||= Gtk::Spinner.new.tap do |widget|
        widget.width_request = 32
        widget.height_request = 32
      end
    end

    def error_box
      @error_box ||= Gtk::Box.new(:vertical, 12).tap do |box|
        box.halign = :center
        box.valign = :center
      end
    end

    def error_title
      @error_title ||= Gtk::Label.new.tap do |label|
        label.wrap = true
        label.justify = :center
        label.add_css_class('title-1')
      end
    end

    def error_message
      @error_message ||= Gtk::Label.new.tap do |label|
        label.wrap = true
        label.justify = :center
      end
    end

    def card_container
      @card_container ||= Gtk::Box.new(:vertical, 12).tap do |box|
        box.halign = :fill
        box.add_css_class('card-container')
      end
    end

    def buttons = @buttons ||= Gtk::CenterBox.new

    def metadata_button
      @metadata_button ||= Gtk::Button.new.tap do |button|
        button.action_name = 'win.metadata'
        button.halign = :center
        button.valign = :end
        button.add_css_class('pill')
        button.child = metadata_content
      end
    end

    def metadata_content
      @metadata_content ||= Adwaita::ButtonContent.new.tap do |content|
        content.icon_name = 'code-symbolic'
        content.label = _('View Metadata')
      end
    end

    def log_button
      @log_button ||= Gtk::Button.new.tap do |button|
        button.action_name = 'win.log'
        button.halign = :end
        button.hexpand = true
        button.valign = :center
        button.margin_start = 12
        button.tooltip_text = _('Show Logs')
        button.add_css_class('flat')
      end
    end

    def counts_box = @counts_box ||= Gtk::Box.new(:horizontal, 3)

    def inf_count = @inf_count ||= count_badge('info-symbolic')

    def war_count = @war_count ||= count_badge('dialog-warning-symbolic')

    def err_count = @err_count ||= count_badge('dialog-error-symbolic')

    def count_badge(icon_name)
      Adwaita::ButtonContent.new.tap do |content|
        content.icon_name = icon_name
      end
    end
end
