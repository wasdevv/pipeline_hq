# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  def create?
    return false unless membership.present?

    record.conversation.participants.exists?(user_id: user.id)
  end
end
