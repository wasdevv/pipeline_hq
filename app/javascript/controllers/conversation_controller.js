import { Controller } from "@hotwired/stimulus"

const GROUP_GAP_SECONDS = 5 * 60

export default class extends Controller {
  static targets = ["scroll"]

  connect() {
    this.apply()
    this.scrollToBottom()
    this.observer = new MutationObserver(() => {
      this.apply()
      this.scrollToBottom()
    })
    if (this.hasScrollTarget) {
      this.observer.observe(this.scrollTarget, { childList: true, subtree: true })
    }
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  scrollToBottom() {
    if (!this.hasScrollTarget) return
    this.scrollTarget.scrollTop = this.scrollTarget.scrollHeight
  }

  apply() {
    if (!this.hasScrollTarget) return
    const bubbles = this.scrollTarget.querySelectorAll("[data-sender-id]")
    bubbles.forEach((node, idx) => {
      const prev = bubbles[idx - 1]
      const next = bubbles[idx + 1]
      const sameAsPrev = prev && this.sameGroup(prev, node)
      const sameAsNext = next && this.sameGroup(node, next)
      this.toggleAvatar(node, !sameAsPrev)
      this.toggleTimestamp(node, !sameAsNext)
      this.toggleBubbleCorner(node, sameAsPrev, sameAsNext)
      this.tightenSpacing(node, sameAsPrev)
    })
  }

  sameGroup(a, b) {
    if (a.dataset.senderId !== b.dataset.senderId) return false
    const ta = Number(a.dataset.createdAt)
    const tb = Number(b.dataset.createdAt)
    return Math.abs(tb - ta) <= GROUP_GAP_SECONDS
  }

  toggleAvatar(node, show) {
    const avatar = node.querySelector('[data-message-target="avatar"]')
    if (!avatar) return
    avatar.classList.toggle("invisible", !show)
  }

  toggleTimestamp(node, show) {
    const ts = node.querySelector('[data-message-target="timestamp"]')
    if (!ts) return
    ts.classList.toggle("hidden", !show)
  }

  toggleBubbleCorner(node, sameAsPrev, sameAsNext) {
    const bubble = node.querySelector('[data-message-target="bubble"]')
    if (!bubble) return
    const sent = node.classList.contains("justify-end")
    bubble.classList.remove("rounded-tr-sm", "rounded-br-sm", "rounded-tl-sm", "rounded-bl-sm")
    if (sent) {
      if (sameAsPrev) bubble.classList.add("rounded-tr-sm")
      if (sameAsNext) bubble.classList.add("rounded-br-sm")
    } else {
      if (sameAsPrev) bubble.classList.add("rounded-tl-sm")
      if (sameAsNext) bubble.classList.add("rounded-bl-sm")
    }
  }

  tightenSpacing(node, sameAsPrev) {
    const li = node.closest("li")
    if (!li) return
    li.classList.toggle("mt-0.5", sameAsPrev)
    li.classList.toggle("mt-3", !sameAsPrev)
  }
}
