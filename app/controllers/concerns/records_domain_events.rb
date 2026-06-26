# frozen_string_literal: true

module RecordsDomainEvents
  extend ActiveSupport::Concern

  included do
    after_action :record_domain_event, only: %i[create update destroy], if: :audit_eligible?
  end

  private

  def audit_eligible?
    return false unless current_workspace.present?

    subject = audit_subject
    return false if subject.blank?

    case action_name
    when "destroy" then subject.destroyed?
    else subject.persisted? && subject.errors.empty?
    end
  end

  def record_domain_event
    DomainEvents::Record.call(
      kind:      audit_kind,
      workspace: audit_workspace,
      actor:     current_user,
      subject:   audit_subject,
      metadata:  audit_metadata
    )
  end

  def audit_subject
    instance_variable_get(:"@#{controller_name.singularize}")
  end

  def audit_workspace
    current_workspace
  end

  def audit_kind
    verb = case action_name
    when "create"  then "created"
    when "update"  then "updated"
    when "destroy" then "destroyed"
    end
    "#{controller_name.singularize}.#{verb}"
  end

  def audit_metadata
    {}
  end
end
