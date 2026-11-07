# frozen_string_literal: true

require_relative "rb/version"

# Gem version namespace for share-preview-rb.
#
# This is deliberately separate from `lib/share_preview.rb` (the GTK
# application entry point, which requires `gtk4`/`adwaita` and therefore
# cannot be loaded on a display-free test run). `spec/spec_helper.rb` only
# needs the version constant, so it requires this file instead.
