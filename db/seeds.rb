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

  workspace = user.current_workspace || Workspace.find_or_create_by!(slug: "demo") do |w|
    w.name = "Workspace Demo"
    w.owner = user
  end
  WorkspaceMembership.find_or_create_by!(workspace: workspace, user: user) { |m| m.role = :owner }
  user.update!(current_workspace: workspace) if user.current_workspace_id.nil?

  teammate = User.find_or_initialize_by(email_address: "ana@pipelinehq.test")
  teammate.assign_attributes(
    name:                  "Ana Ribeiro",
    password:              "AnaTeam!2026PipelineHQ",
    password_confirmation: "AnaTeam!2026PipelineHQ",
    confirmed_at:          Time.current
  )
  teammate.save!
  WorkspaceMembership.find_or_create_by!(workspace: workspace, user: teammate) { |m| m.role = :member }
  puts "Seeded ana@pipelinehq.test / AnaTeam!2026PipelineHQ"

  Current.workspace = workspace
  result = Conversations::FindOrCreateDirect.call(workspace: workspace, initiator: teammate, recipient: user)
  conversation = result.payload
  if conversation.messages.empty?
    Messages::Send.call(conversation: conversation, sender: teammate, body: "Oi! Bem-vindo ao PipelineHQ — qualquer dúvida me chama por aqui.")
    Messages::Send.call(conversation: conversation, sender: teammate, body: "Acabei de subir um lead novo na sua fila, dá uma olhada quando puder.")
  end
  puts "Seeded 1 conversa entre Demo User e Ana Ribeiro"
end
