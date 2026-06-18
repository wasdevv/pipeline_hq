# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) { allow(Passwords::BreachCheck).to receive(:call).and_return(false) }
end
