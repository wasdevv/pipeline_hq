import { Controller } from "@hotwired/stimulus"
import cable from "channels/consumer"

export default class extends Controller {
  static targets = ["status", "dot", "label"]
  static values = {
    workspaceId: Number,
    recipientId: Number,
    onlineLabel: { type: String, default: "Online" },
    offlineLabel: { type: String, default: "Offline" }
  }

  connect() {
    this.subscribe()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  async subscribe() {
    try {
      this.subscription = await cable.subscribeTo(
        { channel: "WorkspacePresenceChannel", workspace_id: this.workspaceIdValue },
        { received: (data) => this.received(data) }
      )
    } catch (error) {
      console.warn("[presence] subscribe failed", error)
    }
  }

  received(data) {
    if (!data) return
    if (data.type === "snapshot") {
      const ids = (data.online_ids || []).map(Number)
      this.setOnline(ids.includes(this.recipientIdValue))
    } else if (data.type === "update" && Number(data.user_id) === this.recipientIdValue) {
      this.setOnline(Boolean(data.online))
    }
  }

  setOnline(online) {
    if (this.hasDotTarget) {
      this.dotTarget.classList.toggle("bg-emerald-500", online)
      this.dotTarget.classList.toggle("bg-zinc-300", !online)
      this.dotTarget.classList.toggle("dark:bg-zinc-600", !online)
    }
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = online ? this.onlineLabelValue : this.offlineLabelValue
    }
  }
}
