# frozen_string_literal: true

if Rails.env.development?
  user = User.find_or_initialize_by(email_address: "demo@pipelinehq.test")
  user.assign_attributes(
    name:                  "Demo User",
    password:              "DemoUser!2026PipelineHQ",
    password_confirmation: "DemoUser!2026PipelineHQ",
    confirmed_at:          Time.current
  )
  user.save!
  puts "Seeded demo@pipelinehq.test / DemoUser!2026PipelineHQ"
end
