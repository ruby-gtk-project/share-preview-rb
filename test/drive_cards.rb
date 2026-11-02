# frozen_string_literal: true

# Builds every card layout, both dialogs and every log level from synthesised
# data, so each widget class is exercised without touching the network.
#
# Run it with: nix develop --command xvfb-run -a ruby test/drive_cards.rb

require 'gdk_pixbuf2'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'main'
require 'card_box'
require 'data_dialog'
require 'log_dialog'
require 'log_model'
require 'metadata_row'
require 'shortcuts_window'
require 'about_dialog'

IMAGE = GdkPixbuf::Pixbuf.new(
  colorspace:      :rgb,
  has_alpha:       false,
  bits_per_sample: 8,
  width:           500,
  height:          250,
).tap { |pixbuf| pixbuf.fill!(0x33d17aff) }.save(nil, 'png')

# A Card without running the builder: the same fields, filled directly.
class FakeCard
  attr_reader :title, :site, :favicon, :description, :image, :size, :social

  def initialize(social, size, image)
    @social = social
    @size = size
    @image = image
    @favicon = image
    @title = 'A title that is long enough to need more than one line in the card layout'
    @site = 'example.com'
    @description = 'A description for the card, long enough to be clamped by the layouts that clamp it.'
  end
end

# GTK4 has no children accessor, so walk the sibling chain.
def count_rows(list)
  count = 0
  child = list.first_child
  while child
    count += 1
    child = child.next_sibling
  end
  count
end

failures = []
app = App.new(app_id: 'org.rubygtkproject.SharePreview.Cards', present: false)
app.build

GLib::Timeout.add(100) do
  Style.install
  window = Gtk::Window.new
  box = Gtk::Box.new(:vertical, 0)
  window.child = box

  [CardSize::SMALL, CardSize::MEDIUM, CardSize::LARGE].each do |size|
    Social.all.each do |social|
      [IMAGE, nil].each do |image|
        card = FakeCard.new(social, size, image)
        CardBox.from_card(card).then { |card_box| box.append(card_box.root) }
      rescue StandardError => e
        failures.push("#{social} #{size} image=#{!image.nil?}: #{e.class}: #{e.message}")
      end
    end
  end
  puts "built #{3 * Social.all.size * 2} card boxes"

  [CardError::NOT_ENOUGH_DATA, CardError::TWITTER_NO_CARD_FOUND].each do |kind|
    CardBox.from_error(CardError.new(kind)).then { |card_box| box.append(card_box.root) }
  rescue StandardError => e
    failures.push("error card #{kind}: #{e.class}: #{e.message}")
  end
  puts 'built both error cards'

  logger = LogModel.new
  [LogItem::DEBUG, LogItem::INFO, LogItem::WARNING, LogItem::ERROR].each do |level|
    logger.log(level, "a #{level} line")
  end
  dialog = LogDialog.new(logger.model)
  dialog.build
  rows = count_rows(dialog.list)
  unless rows == 4
    failures.push("log dialog showed #{rows} rows, expected 4")
  end
  unless logger.worrying_count == [1, 1, 1]
    failures.push("worrying_count was #{logger.worrying_count.inspect}, expected [1, 1, 1]")
  end
  puts "log dialog: #{rows} rows, counts #{logger.worrying_count.inspect}"

  data = PageData.new(
    url:         'example.com',
    title:       'A Page',
    metadata:    [
      Meta.new(name: nil, property: ['og:title'], content: 'OG Title', image: nil),
      Meta.new(name: 'description', property: [], content: 'A description', image: nil),
    ],
    body_images: [Image.build('http://example.com/a.png', URI.parse('http://example.com/'))],
  )
  data_dialog = DataDialog.new(data)
  data_dialog.build
  metadata_rows = count_rows(data_dialog.metadata_list)
  image_rows = count_rows(data_dialog.images_list)
  unless metadata_rows == 2
    failures.push("data dialog showed #{metadata_rows} metadata rows, expected 2")
  end
  unless image_rows == 1
    failures.push("data dialog showed #{image_rows} image rows, expected 1")
  end
  puts "data dialog: #{metadata_rows} metadata rows, #{image_rows} image rows"

  ShortcutsWindow.new.build
  AboutDialog.new(application_icon: 'org.rubygtkproject.SharePreview', version: '0.1.0').dialog
  puts 'built the shortcuts and about dialogs'

  app.quit_now
  false
end

app.run([])

case failures
when [] then puts 'drive_cards: OK'
else
  failures.each { |failure| warn "drive_cards: #{failure}" }
  exit(1)
end
