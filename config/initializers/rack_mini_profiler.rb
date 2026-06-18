# frozen_string_literal: true

return unless Rails.env.development?

require "rack-mini-profiler"

Rack::MiniProfiler.config.position        = "top-left"
Rack::MiniProfiler.config.start_hidden    = false
Rack::MiniProfiler.config.skip_paths      = %w[/assets /packs /favicon.ico]
Rack::MiniProfiler.config.storage_options = { path: Rails.root.join("tmp/miniprofiler") }
Rack::MiniProfiler.config.storage         = Rack::MiniProfiler::FileStore
