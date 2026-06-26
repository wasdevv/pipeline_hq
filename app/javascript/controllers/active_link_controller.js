import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  activate(event) {
    const link = event.currentTarget
    this.itemTargets.forEach((t) => t.setAttribute("aria-current", "false"))
    link.setAttribute("aria-current", "page")
  }
}
