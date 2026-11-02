# frozen_string_literal: true

# Drives the app end to end against a page served from this process: types a
# url into the window, waits for the card, then opens both dialogs.
#
# Run it with: nix develop --command xvfb-run -a ruby test/drive_window.rb

require 'socket'
require 'gdk_pixbuf2'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'main'

PNG = GdkPixbuf::Pixbuf.new(
  colorspace:      :rgb,
  has_alpha:       false,
  bits_per_sample: 8,
  width:           800,
  height:          418,
).tap { |pixbuf| pixbuf.fill!(0x3584e4ff) }.save(nil, 'png')

PAGE = <<~HTML
  <html><head>
  <title>A Page With Everything</title>
  <meta property="og:title" content="Open Graph Title">
  <meta property="og:description" content="#{'A description long enough for LinkedIn to stop complaining about it. ' * 2}">
  <meta property="og:image" content="/image.png">
  <meta property="og:site_name" content="Example Site">
  <meta property="og:type" content="website">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="icon" href="/favicon.png">
  </head><body><img src="/image.png"></body></html>
HTML

server = TCPServer.new('127.0.0.1', 0)
port = server.addr[1]

Thread.new do
  loop do
    client = server.accept
    request = client.gets.to_s
    while (line = client.gets) && line.strip != ''
    end

    if request.include?('.png')
      client.write("HTTP/1.1 200 OK\r\nContent-Type: image/png\r\nContent-Length: #{PNG.bytesize}\r\nConnection: close\r\n\r\n")
      client.write(PNG)
    else
      client.write("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: #{PAGE.bytesize}\r\nConnection: close\r\n\r\n")
      client.write(PAGE)
    end
    client.close
  rescue IOError, SystemCallError
    nil
  end
end

app = App.new(
  app_id:   'org.rubygtkproject.SharePreview.Drive',
  settings: Settings.new(path: "/tmp/share-preview-drive-#{Process.pid}.json"),
)
app.build

failures = []
checks = 0

GLib::Timeout.add(500) do
  checks += 1
  window = app.send(:active_window)
  page = window&.send(:stack)&.visible_child_name

  case [page, checks > 40]
  in ['card', _]
    counts = window.logger.worrying_count
    puts "card shown; log counts (info, warning, error) = #{counts.inspect}"
    puts "log lines: #{window.logger.n_items}"
    window.logger.items.first(8).each { |item| puts "  [#{item.level}] #{item.text}" }

    Social.all.each { |social| window.send(:social).selected = social.index }
    puts 'cycled every platform'

    window.send(:show_metadata)
    window.send(:show_log)
    puts 'opened both dialogs'

    app.quit_now
    false
  in [_, true]
    failures.push("card never appeared; stuck on #{page.inspect}")
    app.quit_now
    false
  else
    true
  end
end

app.run(["http://127.0.0.1:#{port}/"])

case failures
when [] then puts 'drive_window: OK'
else
  failures.each { |failure| warn "drive_window: #{failure}" }
  exit(1)
end
