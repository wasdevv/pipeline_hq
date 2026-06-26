# frozen_string_literal: true

module Conversations
  class FindOrCreateDirect
    def self.call(workspace:, initiator:, recipient:)
      new(workspace, initiator, recipient).call
    end

    def initialize(workspace, initiator, recipient)
      @workspace = workspace
      @initiator = initiator
      @recipient = recipient
    end

    def call
      return Result.failure(:self_dm)        if @initiator.id == @recipient.id
      return Result.failure(:not_in_workspace) unless both_members?

      signature = Conversation.direct_signature_for([ @initiator, @recipient ])
      existing  = @workspace.conversations.kind_direct.find_by(participants_signature: signature)
      return Result.success(:found, existing) if existing

      conversation = create_conversation(signature)
      DomainEvents::Record.call(
        kind: "conversation.created",
        workspace: @workspace,
        actor: @initiator,
        subject: conversation,
        metadata: { kind: "direct", participants: [ @initiator.id, @recipient.id ] }
      )
      Result.success(:created, conversation)
    end

    private

    def both_members?
      member_ids = @workspace.workspace_memberships.pluck(:user_id)
      member_ids.include?(@initiator.id) && member_ids.include?(@recipient.id)
    end

    def create_conversation(signature)
      Conversation.transaction do
        conversation = @workspace.conversations.create!(
          kind: :direct,
          participants_signature: signature
        )
        conversation.participants.create!(user: @initiator)
        conversation.participants.create!(user: @recipient)
        conversation
      end
    end
  end
end
