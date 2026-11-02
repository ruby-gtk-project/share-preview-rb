# frozen_string_literal: true

require_relative '../main'

module SharePreview
  # The gem-facing handle on the application.
  #
  # The application itself is App in lib/main.rb, ported from upstream's
  # src/application.rs and src/main.rs; this is the namespaced constant the
  # gem's executable launches it through.
  Application = ::App
end
