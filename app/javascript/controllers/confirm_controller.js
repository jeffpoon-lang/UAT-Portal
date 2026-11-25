import { Controller } from "@hotwired/stimulus"

// A confirm dialog for forms that skip Turbo (data-turbo="false"), where
// data-turbo-confirm doesn't apply.
export default class extends Controller {
  static values = { message: String }

  check(event) {
    if (!window.confirm(this.messageValue)) event.preventDefault()
  }
}
