import { Controller } from "@hotwired/stimulus"

// The file input is hidden inside a button-like label (the browser's own
// "Choose Files" text is in English); show how many images were picked.
export default class extends Controller {
  static targets = ["input", "label"]
  static values = { empty: { type: String, default: "加截圖" } }

  update() {
    const count = this.inputTarget.files.length
    this.labelTarget.textContent = count ? `已揀 ${count} 張` : this.emptyValue
  }
}
