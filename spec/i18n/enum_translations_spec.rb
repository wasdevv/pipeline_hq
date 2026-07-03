# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enum translations (pt-BR)" do
  ENUM_INVENTORY = {
    deal:                 { status: %w[open won lost] },
    activity:             { kind:   %w[call email meeting note task] },
    conversation:         { kind:   Conversation.kinds.keys },
    workspace_membership: { role:   WorkspaceMembership.roles.keys },
    auth_event:           { kind:   AuthEvent::KINDS }
  }.freeze

  ENUM_INVENTORY.each do |model, fields|
    fields.each do |field, values|
      values.each do |value|
        it "traduz enums.#{model}.#{field}.#{value}" do
          I18n.with_locale(:"pt-BR") do
            key = "enums.#{model}.#{field}.#{value}"
            translated = I18n.t(key, default: "")
            expect(translated).to be_present, "esperava tradução em pt-BR para `#{key}` em config/locales/enums.pt-BR.yml"
            expect(translated).not_to start_with("translation missing")
          end
        end
      end
    end
  end
end
