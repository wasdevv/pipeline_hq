# frozen_string_literal: true

require "rails_helper"
require_relative "shared_examples/crm_policy"

RSpec.describe ContactPolicy do
  it_behaves_like "a CRM policy", factory: :contact
end
