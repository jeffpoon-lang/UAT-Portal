import { Controller } from "@hotwired/stimulus"

// Toast messages. Notices hide after 6 seconds unless the pointer or focus
// is on them; alerts stay until closed.
export default class extends Controller {
  static values = { autohide: Boolean }

  connect() {
    if (this.autohideValue) this.timer = setTimeout(() => this.dismiss(), 6000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  pause() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.remove()
  }
}
