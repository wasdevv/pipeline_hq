# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    if current_workspace.present?
      ws = current_workspace

      @stats = {
        pipeline_cents:   ws.deals.where.not(status: "lost").sum(:amount_cents),
        deals_open:       ws.deals.where.not(status: %w[won lost]).count,
        deals_won_30d:    ws.deals.where(status: "won").where("updated_at >= ?", 30.days.ago).count,
        accounts_total:   ws.accounts.count,
        contacts_total:   ws.contacts.count,
        activities_30d:   ws.activities.where("occurred_at >= ?", 30.days.ago).count
      }

      @recent_events = ws.domain_events.recent.includes(:actor, :subject).limit(8)
    else
      @stats = {}
      @recent_events = []
    end

    @auth_events = current_user.auth_events.recent.limit(5)
  end
end
