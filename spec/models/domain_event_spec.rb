# frozen_string_literal: true

require "rails_helper"

RSpec.describe DomainEvent, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workspace).inverse_of(:domain_events) }

    it "declares belongs_to :actor as class User, optional" do
      reflection = DomainEvent.reflect_on_association(:actor)
      expect(reflection.options[:class_name]).to eq("User")
      expect(reflection.options[:optional]).to be(true)
    end

    it "declares belongs_to :subject as polymorphic, optional" do
      reflection = DomainEvent.reflect_on_association(:subject)
      expect(reflection.options[:polymorphic]).to be(true)
      expect(reflection.options[:optional]).to be(true)
    end
  end

  describe "validations" do
    subject { build(:domain_event) }

    it { is_expected.to validate_presence_of(:kind) }
    it { is_expected.to validate_inclusion_of(:kind).in_array(DomainEvent::KINDS) }

    it "accepts empty-hash metadata (default state)" do
      event = build(:domain_event, metadata: {})
      expect(event).to be_valid
    end

    it "accepts non-empty metadata" do
      event = build(:domain_event, metadata: { "key" => "value" })
      expect(event).to be_valid
    end
  end

  describe "schema" do
    it "stores metadata as a jsonb hash" do
      event = create(:domain_event)
      expect(event.reload.metadata).to be_a(Hash)
    end

    it "actor_id is nullable (actor is optional)" do
      event = build(:domain_event, actor_id: nil)
      expect(event).to be_valid
    end

    it "accepts a polymorphic subject" do
      account = create(:account)
      event = build(:domain_event, subject: account, workspace: account.workspace)
      expect(event).to be_valid
    end
  end

  describe "persisting with actor_id" do
    it "can be saved with a user's actor_id" do
      user      = create(:user)
      workspace = create(:workspace, owner: user)
      event     = create(:domain_event, workspace: workspace, actor_id: user.id)
      expect(event.reload.actor_id).to eq(user.id)
    end
  end
end
