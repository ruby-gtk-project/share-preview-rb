# frozen_string_literal: true

# Drives the window in a locale upstream ships a catalogue for and reads the
# strings back off the widgets, proving the port's msgids are the keys the
# inherited po/*.po files were translated against.
#
# Run it with: nix develop --command xvfb-run -a ruby test/drive_translated.rb
# The catalogues have to be compiled first: rake translations.

# Set before 'main' is required: lib/i18n.rb binds the text domain as it loads,
# and gettext reads LANGUAGE on the first lookup.
ENV['LANGUAGE'] = 'de'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'main'

# The German each message is expected to come back as, straight out of
# po/de.po, keyed by the English msgid so a failure names the message that
# stopped resolving.
EXPECTATIONS = {
  'Share Preview'                      => 'Sharing-Vorschau',
  'Toggle Color Scheme'                => 'Farbschema wechseln',
  'Main Menu'                          => 'Hauptmenü',
  'Go'                                 => 'Los',
  'Set a URL to preview'               => 'URL eingeben für Vorschau',
  'View Metadata'                      => 'Metadaten anzeigen',
  'Show Logs'                          => 'Protokolle anzeigen',
  'Network Error'                      => 'Netzwerk-Fehler',
  'Unexpected Error'                   => 'Unerwarteter Fehler',
  'Couldn’t connect to the given URL.' => 'Keine Verbindung mit angegebener URL möglich.',
  'Card Error'                         => 'Karten-Fehler',
  'Scraping Log'                       => 'Scraping-Protokoll',
  'WARNING'                            => 'WARNUNG',
  'Metadata'                           => 'Metadaten',
  'Body Images'                        => 'Body-Bilder',
  'Nothing to Show'                    => 'Nichts anzuzeigen',
  'General'                            => 'Allgemein',
  'Focus the URL entry'                => 'URL-Eintrag fokussieren',
  'Show Shortcuts'                     => 'Tastenkürzel anzeigen',
  'Quit'                               => 'Beenden',
}.freeze

app = App.new(
  app_id:   'org.rubygtkproject.SharePreview.Translated',
  settings: Settings.new(path: "/tmp/share-preview-translated-#{Process.pid}.json"),
  present:  false,
)
app.build

failures = []

# Every string the widgets hold before a url is scraped, plus the two dialogs,
# the card box's error page, the log row levels and the shortcuts section.
def strings_shown(window)
  DataDialog.new(PageData.new).tap(&:build).then do |data_dialog|
    CardBox.new.tap(&:build).then do |card_box|
      [
        window.root.title,
        window.send(:color_scheme).tooltip_text,
        window.send(:menu_button).tooltip_text,
        window.send(:url_entry).secondary_icon_tooltip_text,
        window.send(:start_page).title,
        window.send(:metadata_content).label,
        window.send(:log_button).tooltip_text,
        Window::NETWORK_TITLE,
        Window::UNEXPECTED_TITLE,
        Window::CONNECTION_MESSAGE,
        card_box.error_title.label,
        LogDialog.new(window.logger.model).dialog.title,
        *LogRow::LEVELS.values.map { |style| style[:label] },
        ShortcutsWindow::GROUP,
        *ShortcutsWindow::SHORTCUTS.map(&:first),
        *[data_dialog.metadata_page, data_dialog.images_page]
          .map { |page| data_dialog.view_stack.get_page(page).title },
        data_dialog.send(:metadata_empty).label,
      ]
    end
  end
end

GLib::Timeout.add(500) do
  strings_shown(app.send(:active_window)).join("\n").then do |shown|
    EXPECTATIONS.each do |msgid, translation|
      unless shown.include?(translation)
        failures.push("#{msgid.inspect} did not come back as #{translation.inspect}")
      end
    end
  end

  app.quit_now
  false
end

app.run([])

case failures
when [] then puts "drive_translated: OK (#{EXPECTATIONS.length} messages in de)"
else
  failures.each { |failure| warn "drive_translated: #{failure}" }
  exit(1)
end
