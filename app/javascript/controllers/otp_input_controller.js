import { Controller } from "@hotwired/stimulus"

// otp-input: força entrada numérica, remove espaços, limita a 8 caracteres
// (6 para TOTP, até 8 para backup codes alfanuméricos curtos).
export default class extends Controller {
  connect() {
    this.onInput = this.onInput.bind(this)
    this.element.addEventListener("input", this.onInput)
  }

  disconnect() {
    this.element.removeEventListener("input", this.onInput)
  }

  onInput() {
    this.element.value = this.element.value.replace(/\s+/g, "").slice(0, 8)
  }
}
