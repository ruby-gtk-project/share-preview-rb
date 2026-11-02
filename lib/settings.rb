# frozen_string_literal: true

require 'fileutils'
require 'json'

# Settings holds the same keys as upstream's SharePreview GSettings schema.
#
# Ported from upstream's data/com.rafaelmardojai.SharePreview.gschema.xml.in,
# which declares two keys: `social`, the platform the window's drop-down last
# had selected, and `dark-theme`, which the schema declares but no upstream
# source ever reads or writes.
#
# Upstream uses GSettings, which needs a compiled schema installed into the
# system's glib-2.0/schemas directory; requiring an install step to run the
# app from a checkout is worse than the alternative, so the same keys,
# defaults and semantics are backed by a small JSON file under
# XDG_CONFIG_HOME instead — the same choice the pilot port made.
class Settings
  DEFAULTS = {
    'social'     => '',
    'dark-theme' => false,
  }.freeze

  def initialize(path: nil)
    @path = path || default_path
    @values = DEFAULTS.merge(read)
  end

  def [](key) = @values.fetch(key.to_s, DEFAULTS[key.to_s])

  def []=(key, value)
    @values[key.to_s] = value
    write
    value
  end

  def location = @path

  def social = self['social'].to_s

  def social=(value)
    self['social'] = value.to_s
  end

  def dark_theme? = self['dark-theme'] == true

  def dark_theme=(value)
    self['dark-theme'] = value == true
  end

  private

    def default_path
      File.join(
        ENV.fetch('XDG_CONFIG_HOME', File.expand_path('~/.config')),
        'share-preview-rb',
        'settings.json',
      )
    end

    def read
      case File.exist?(@path)
      when true then JSON.parse(File.read(@path))
      else {}
      end
    rescue JSON::ParserError => e
      warn "Error parsing #{@path}: #{e.message}"
      {}
    end

    def write
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(@values))
    end
end
