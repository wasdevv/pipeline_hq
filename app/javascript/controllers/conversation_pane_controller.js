import { Controller } from "@hotwired/stimulus"

const MOBILE_BREAKPOINT = 768

export default class extends Controller {
  static targets = ["sidebar", "thread"]

  connect() {
    this.handler = () => this.refresh()
    document.addEventListener("turbo:frame-load", this.handler)
    document.addEventListener("turbo:load", this.handler)
    window.addEventListener("popstate", this.handler)
    window.addEventListener("resize", this.handler)
    this.refresh()
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.handler)
    document.removeEventListener("turbo:load", this.handler)
    window.removeEventListener("popstate", this.handler)
    window.removeEventListener("resize", this.handler)
  }

  refresh() {
    const isMobile = window.innerWidth < MOBILE_BREAKPOINT
    if (!isMobile) {
      this.sidebarTarget.classList.remove("hidden")
      this.threadTarget.classList.remove("hidden")
      return
    }
    const onConversation = /^\/conversations\/\d+/.test(window.location.pathname)
    this.sidebarTarget.classList.toggle("hidden", onConversation)
    this.threadTarget.classList.toggle("hidden", !onConversation)
  }
}
