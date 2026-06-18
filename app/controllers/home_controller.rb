# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    @auth_events = current_user.auth_events.recent.limit(10)
  end
end
