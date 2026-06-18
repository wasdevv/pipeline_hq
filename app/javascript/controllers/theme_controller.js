import { Controller } from "@hotwired/stimulus"

// Theme toggle: persists in localStorage, falls back to system preference.
// Anti-flash inline script in layout applies the class before CSS loads.
export default class extends Controller {
  static targets = ["sun", "moon"]

  connect() {
    this.refreshIcons()
  }

  toggle() {
    const root = document.documentElement
    const isDark = root.classList.toggle("dark")
    localStorage.setItem("theme", isDark ? "dark" : "light")
    this.refreshIcons()
  }

  refreshIcons() {
    const isDark = document.documentElement.classList.contains("dark")
    if (this.hasSunTarget)  this.sunTarget.classList.toggle("hidden", !isDark)
    if (this.hasMoonTarget) this.moonTarget.classList.toggle("hidden", isDark)
  }
}
