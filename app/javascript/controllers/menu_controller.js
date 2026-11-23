import { Controller } from "@hotwired/stimulus"

// Closes a <details> dropdown on a click outside it or on Escape.
export default class extends Controller {
  connect() {
    this.closeOnOutsideClick = (event) => {
      if (!this.element.contains(event.target)) this.element.open = false
    }
    document.addEventListener("click", this.closeOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  keydown(event) {
    if (event.key === "Escape" && this.element.open) {
      this.element.open = false
      this.element.querySelector("summary").focus()
    }
  }
}
