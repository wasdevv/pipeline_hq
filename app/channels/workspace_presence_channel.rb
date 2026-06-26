# frozen_string_literal: true

class WorkspacePresenceChannel < ApplicationCable::Channel
  def subscribed
    workspace_id = params[:workspace_id].to_i
    return reject unless authorized?(workspace_id)

    stream_from stream_name(workspace_id)
    became_online = Presence::Tracker.add(workspace_id, current_user.id)
    broadcast_change(workspace_id, current_user.id, online: true) if became_online
    transmit(type: "snapshot", online_ids: Presence::Tracker.online_ids(workspace_id))
  end

  def unsubscribed
    workspace_id = params[:workspace_id].to_i
    return unless current_user

    became_offline = Presence::Tracker.remove(workspace_id, current_user.id)
    broadcast_change(workspace_id, current_user.id, online: false) if became_offline
  end

  private

  def authorized?(workspace_id)
    current_user.workspace_memberships.exists?(workspace_id: workspace_id)
  end

  def stream_name(workspace_id)
    "workspace_presence_#{workspace_id}"
  end

  def broadcast_change(workspace_id, user_id, online:)
    ActionCable.server.broadcast(
      stream_name(workspace_id),
      type: "update",
      user_id: user_id,
      online: online
    )
  end
end
