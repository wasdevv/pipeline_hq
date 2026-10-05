import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "submit"]

  connect() {
    this.scrollArea = this.element.closest("section")?.querySelector("[data-chat-scroll]")
    this.observer = new MutationObserver(() => this.scrollToBottom())
    if (this.scrollArea) this.observer.observe(this.scrollArea, { childList: true, subtree: true })
    this.scrollToBottom()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  keydown(event) {
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return

    event.preventDefault()
    if (this.inputTarget.value.trim() === "" || this.submitTarget.disabled) return
    this.formTarget.requestSubmit()
  }

  lock() {
    this.submitTarget.disabled = true
    this.inputTarget.setAttribute("aria-busy", "true")
  }

  unlock(event) {
    this.submitTarget.disabled = false
    this.inputTarget.removeAttribute("aria-busy")
    if (event.detail.success) this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  scrollToBottom() {
    if (this.scrollArea) this.scrollArea.scrollTop = this.scrollArea.scrollHeight
  }
}
