import { Controller } from "@hotwired/stimulus"

// The admin menu on phones: a native <dialog> opened with showModal(),
// which traps focus and closes on Escape by itself.
export default class extends Controller {
  static targets = ["dialog", "button"]

  connect() {
    this.closeBeforeCache = () => this.close()
    document.addEventListener("turbo:before-cache", this.closeBeforeCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.closeBeforeCache)
  }

  open() {
    this.dialogTarget.showModal()
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  closed() {
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  // A click on the dimmed area outside the panel lands on the dialog itself
  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
