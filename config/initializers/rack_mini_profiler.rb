# frozen_string_literal: true

return unless Rails.env.development?

require "rack-mini-profiler"

Rack::MiniProfiler.config.position        = "top-left"
Rack::MiniProfiler.config.start_hidden    = false
Rack::MiniProfiler.config.skip_paths      = %w[/assets /packs /favicon.ico]
storage_path = Rails.root.join("tmp/miniprofiler").to_s
FileUtils.mkdir_p(storage_path)
Rack::MiniProfiler.config.storage_options = { path: storage_path }
Rack::MiniProfiler.config.storage         = Rack::MiniProfiler::FileStore
