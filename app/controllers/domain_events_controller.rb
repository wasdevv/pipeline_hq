# frozen_string_literal: true

class DomainEventsController < ApplicationController
  include WorkspaceScoped

  PAGE_SIZE = 50

  def index
    authorize DomainEvent
    scope = policy_scope(DomainEvent).includes(:actor, :subject)
    scope = scope.where(kind: params[:kind]) if params[:kind].present? && DomainEvent::KINDS.include?(params[:kind])
    @domain_events = scope.recent.limit(PAGE_SIZE).offset(offset)
    @current_page  = current_page
    @total_pages   = (policy_scope(DomainEvent).count.to_f / PAGE_SIZE).ceil
  end

  private

  def current_page
    page = params[:page].to_i
    page < 1 ? 1 : page
  end

  def offset
    (current_page - 1) * PAGE_SIZE
  end
end
