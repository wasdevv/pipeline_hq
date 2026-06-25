import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static classes = ["open"]

  connect() {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
  }

  toggle() {
    const expanded = this.element.getAttribute("aria-expanded") === "true"
    this.setOpen(!expanded)
  }

  close() {
    this.setOpen(false)
  }

  setOpen(open) {
    this.element.setAttribute("aria-expanded", open)
    if (this.hasMenuTarget) {
      this.menuTarget.hidden = !open
    }
    if (open) {
      document.addEventListener("click", this.handleOutsideClick)
    } else {
      document.removeEventListener("click", this.handleOutsideClick)
    }
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.setOpen(false)
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.setOpen(false)
      this.element.querySelector("button")?.focus()
    }
  }
}
