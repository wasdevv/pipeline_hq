# frozen_string_literal: true

require "rails_helper"

RSpec.describe DomainEvents::Record do
  include ActiveJob::TestHelper

  let(:workspace) { create(:workspace, owner: create(:user)) }
  let(:actor)     { create(:user) }
  let(:account)   { create(:account, workspace: workspace) }

  describe ".call" do
    it "enqueues DomainEventJob with primitive args" do
      expect {
        described_class.call(kind: "account.created", workspace: workspace, actor: actor, subject: account)
      }.to have_enqueued_job(DomainEventJob).with(
        kind:         "account.created",
        workspace_id: workspace.id,
        actor_id:     actor.id,
        subject_type: "Account",
        subject_id:   account.id,
        metadata:     {}
      )
    end

    it "accepts nil actor (system events)" do
      expect {
        described_class.call(kind: "workspace.created", workspace: workspace, actor: nil)
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(actor_id: nil)
      )
    end

    it "accepts nil subject (workspace-level events)" do
      expect {
        described_class.call(kind: "workspace.created", workspace: workspace, actor: actor)
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(subject_type: nil, subject_id: nil)
      )
    end

    it "extracts subject_type from class name (avoids DeserializationError)" do
      expect {
        described_class.call(kind: "account.created", workspace: workspace, actor: actor, subject: account)
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(subject_type: "Account", subject_id: account.id)
      )
    end

    it "passes metadata through to the job" do
      expect {
        described_class.call(
          kind:      "workspace.created",
          workspace: workspace,
          actor:     actor,
          metadata:  { slug: "acme", name: "Acme" }
        )
      }.to have_enqueued_job(DomainEventJob).with(
        hash_including(metadata: { slug: "acme", name: "Acme" })
      )
    end
  end
end
