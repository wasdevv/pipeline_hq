# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("spec/cassettes").to_s
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false
  config.default_cassette_options = {
    record: ENV["VCR_RECORD"] ? :new_episodes : :none,
    match_requests_on: %i[method uri]
  }
  config.ignore_localhost = true
end

RSpec.configure do |rspec|
  rspec.around(:each) do |example|
    VCR.use_cassette("shared/pwned_breach_check", allow_playback_repeats: true) do
      example.run
    end
  end
end
