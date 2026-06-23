# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user)         { create(:user) }
  let(:user_session) { Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "RSpec/Cable") }

  it "successfully connects with a valid session cookie" do
    cookies.signed[:session_id] = user_session.id

    connect "/cable"

    expect(connection.current_user).to eq(user)
  end

  it "rejects the connection when no session cookie is present" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "rejects the connection when the session cookie points to a missing session" do
    cookies.signed[:session_id] = 99_999_999

    expect { connect "/cable" }.to have_rejected_connection
  end
end
