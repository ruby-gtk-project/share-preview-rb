# frozen_string_literal: true

# Drives everything drive_window.rb, drive_cards.rb and drive_translated.rb
# leave untouched: the empty/splash state, an invalid url, both scraper error
# states, the window and app actions fired through their action groups (not
# by calling the private method directly), the color-scheme toggle, a
# second window opened by app.new-window, the url-focus accel, the help
# overlay, and the data dialog's search filtering and empty state.
#
# Run it with: nix develop --command xvfb-run -a ruby test/drive_actions.rb

require 'socket'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'main'
require 'data_dialog'
require 'data'

CHECKS = []

def check(description)
  ok =
    begin
      yield
    rescue StandardError => e
      puts "    FAIL #{description} (#{e.class}: #{e.message})"
      CHECKS << false
      return false
    end
  puts(ok ? "    ok   #{description}" : "    FAIL #{description}")
  CHECKS << ok
  ok
end

# A closed port: nothing is listening, so connecting to it raises
# Errno::ECONNREFUSED, which HttpClient turns into a NetworkError and
# Scraper into Error::NETWORK_ERROR.
closed_server = TCPServer.new('127.0.0.1', 0)
CLOSED_PORT = closed_server.addr[1]
closed_server.close

# A server that always answers 404, to drive Scraper's Error::UNEXPECTED
# path.
not_found_server = TCPServer.new('127.0.0.1', 0)
NOT_FOUND_PORT = not_found_server.addr[1]
Thread.new do
  loop do
    client = not_found_server.accept
    client.gets.to_s
    while (line = client.gets) && line.strip != ''
    end
    body = 'not found'
    client.write("HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
    client.close
  rescue IOError, SystemCallError
    nil
  end
end

# A server that answers a page with real metadata, to drive the data
# dialog's search filtering against more than one row.
ok_server = TCPServer.new('127.0.0.1', 0)
OK_PORT = ok_server.addr[1]
PAGE = <<~HTML
  <html><head>
  <title>Actions Page</title>
  <meta property="og:title" content="Actions Title">
  <meta property="og:description" content="Actions description, long enough.">
  </head><body></body></html>
HTML
Thread.new do
  loop do
    client = ok_server.accept
    client.gets.to_s
    while (line = client.gets) && line.strip != ''
    end
    client.write("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: #{PAGE.bytesize}\r\nConnection: close\r\n\r\n#{PAGE}")
    client.close
  rescue IOError, SystemCallError
    nil
  end
end

app = App.new(
  app_id:   'org.rubygtkproject.SharePreview.Actions',
  settings: Settings.new(path: "/tmp/share-preview-actions-#{Process.pid}.json"),
)
app.build

# One step per tick, run through GLib::Idle so each has a turn of the main
# loop between it and the last (steps that start a scrape need several
# ticks for the background thread to answer, which `wait_until` below
# handles by re-arming itself).
STEPS = []
STEPS << lambda { |window, _win, stack, _url_entry|
  check('window built with the splash page showing') { stack.visible_child_name == Window::SPLASH }
}

STEPS << lambda { |_window, win, _stack, url_entry|
  # with_scheme prefixes a bare word with http://, so this still fails
  # URI.parse on the embedded space -- the toast + css-class path.
  url_entry.text = 'not a valid url'
  win.activate_action('run', nil)
}

STEPS << lambda { |_window, _win, _stack, url_entry|
  check('invalid url adds the error css class to the entry') { url_entry.css_classes.include?('error') }
}

STEPS << lambda { |_window, win, _stack, url_entry|
  url_entry.remove_css_class('error')
  url_entry.text = "http://127.0.0.1:#{CLOSED_PORT}/"
  win.activate_action('run', nil)
}

STEPS << :wait_for_error
STEPS << lambda { |window, _win, stack, _url_entry|
  check('refused connection shows the Network Error page') do
    stack.visible_child_name == Window::ERROR &&
      window.send(:error_title).label == Window::NETWORK_TITLE
  end
}

STEPS << lambda { |_window, win, _stack, url_entry|
  url_entry.text = "http://127.0.0.1:#{NOT_FOUND_PORT}/"
  win.activate_action('run', nil)
}

STEPS << :wait_for_error
STEPS << lambda { |window, _win, stack, _url_entry|
  check('a 404 shows the Unexpected Error page') do
    stack.visible_child_name == Window::ERROR &&
      window.send(:error_title).label == Window::UNEXPECTED_TITLE
  end
}

STEPS << lambda { |_window, win, _stack, url_entry|
  url_entry.text = "http://127.0.0.1:#{OK_PORT}/"
  win.activate_action('run', nil)
}

STEPS << :wait_for_card
STEPS << lambda { |_window, _win, stack, _url_entry|
  check('win.run, fired through the action group, loads the card') { stack.visible_child_name == Window::CARD }
}

STEPS << lambda { |_window, _win, _stack, _url_entry|
  @windows_before = app.app.windows.length
  app.app.activate_action('new-window', nil)
}

STEPS << lambda { |_window, _win, _stack, _url_entry|
  check('app.new-window opens a second top-level window') { app.app.windows.length == @windows_before + 1 }
}

STEPS << lambda { |window, _win, _stack, _url_entry|
  @dark_before = Adwaita::StyleManager.default.dark?
  window.send(:toggle_color_scheme)
}

STEPS << lambda { |window, _win, _stack, _url_entry|
  check('toggling the color scheme flips StyleManager.dark?') { Adwaita::StyleManager.default.dark? != @dark_before }
  # Leave it as upstream had it, so nothing downstream sees an unexpected
  # scheme.
  window.send(:toggle_color_scheme)
}

STEPS << lambda { |_window, win, _stack, _url_entry|
  win.activate_action('url', nil)
}

STEPS << lambda { |_window, win, _stack, url_entry|
  # has_focus? needs this toplevel to be the display's active window, which
  # the second window (just opened by app.new-window) now is; focus_widget
  # is this window's own idea of which child it would focus, which is what
  # win.url actually sets and is testable regardless of window activation.
  check('win.url (<primary>l\'s action) focuses the url entry') do
    # Entry wraps an internal Gtk::Text that actually takes the focus, so
    # the focus widget is a descendant of url_entry, not url_entry itself.
    focused = win.focus_widget
    focused.equal?(url_entry) || (focused.respond_to?(:ancestor?) && focused.ancestor?(url_entry))
  end
}

STEPS << lambda { |_window, win, _stack, _url_entry|
  win.activate_action('show-help-overlay', nil)
}

STEPS << lambda { |_window, win, _stack, _url_entry|
  check('win.show-help-overlay opened a window over the main one') { app.app.windows.any? { |w| !w.equal?(win) } }
}

STEPS << lambda { |_window, _win, _stack, _url_entry|
  empty_dialog = DataDialog.new(PageData.new)
  empty_dialog.build
  check('a data dialog with no metadata shows its empty page') do
    empty_dialog.send(:metadata_stack).visible_child_name == DataDialog::EMPTY
  end
}

STEPS << lambda { |window, _win, _stack, _url_entry|
  @search_dialog = DataDialog.new(window.instance_variable_get(:@data))
  @search_dialog.build
  check('the scraped data dialog has both metadata rows before searching') { @search_dialog.send(:metadata_model).n_items == 2 }
}

STEPS << lambda { |_window, _win, _stack, _url_entry|
  @search_dialog.send(:metadata_search).text = 'description'
}

STEPS << lambda { |_window, _win, _stack, _url_entry|
  check('searching "description" narrows the metadata list to one row') { @search_dialog.send(:metadata_filter_model).n_items == 1 }
}

STEPS << lambda { |_window, _win, _stack, _url_entry|
  @search_dialog.send(:metadata_search).text = 'no such metadata key anywhere'
}

STEPS << lambda { |_window, _win, _stack, _url_entry|
  check('an unmatched search flips the metadata page to its empty state') do
    @search_dialog.send(:metadata_stack).visible_child_name == DataDialog::EMPTY
  end
}

STEPS << lambda { |_window, _win, _stack, _url_entry|
  app.app.activate_action('about', nil)
  check('app.about presents without raising') { true }
}

STEPS << lambda { |_window, _win, _stack, _url_entry|
  app.app.activate_action('quit', nil)
}

index = 0
ticks = 0
MAX_TICKS = 600
errored = []

# Captured once the window is up, not re-fetched every tick: app.new-window
# (exercised partway through) makes a second window the active one, and
# every step after that must still act on the window this script has been
# driving, not on the fresh blank one.
home_window = nil

GLib::Timeout.add(150) do
  ticks += 1
  home_window ||= app.send(:active_window)
  window = home_window
  win = window&.root
  stack = window&.send(:stack)
  url_entry = window&.send(:url_entry)

  if ticks > MAX_TICKS
    errored << 'watchdog timeout before the script finished its steps'
    app.quit_now
    next false
  end

  step = STEPS[index]

  case step
  when nil
    app.quit_now
    next false
  when :wait_for_error
    if stack.visible_child_name == Window::ERROR
      index += 1
    end
  when :wait_for_card
    if stack.visible_child_name == Window::CARD
      index += 1
    end
  else
    begin
      step.call(window, win, stack, url_entry)
    rescue StandardError => e
      errored << "step #{index} (#{e.class}: #{e.message})"
    end
    index += 1
  end

  true
end

app.run([])

failed = CHECKS.count { |ok| !ok }

puts
puts "#{CHECKS.length - failed} of #{CHECKS.length} checks passed"
errored.each { |message| puts "  errored step: #{message}" }
puts((failed.zero? && errored.empty?) ? 'DRIVE OK' : "DRIVE FAILED (#{failed + errored.length})")
exit((failed.zero? && errored.empty?) ? 0 : 1)
