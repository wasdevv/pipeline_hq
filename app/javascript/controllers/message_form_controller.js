import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  handleKeydown(event) {
    if (event.key !== "Enter" || event.shiftKey) return

    event.preventDefault()
    this.element.requestSubmit()
  }

  submit() {
    requestAnimationFrame(() => {
      if (this.hasInputTarget) {
        this.inputTarget.value = ""
        this.inputTarget.focus()
      }
    })
  }
}
