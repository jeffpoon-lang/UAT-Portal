import { Controller } from "@hotwired/stimulus"

// The file input is hidden inside a button-like label (the browser's own
// "Choose Files" text is in English). Show how many images were picked, or
// the file's name when the input takes a single file.
export default class extends Controller {
  static targets = ["input", "label"]
  static values = { empty: { type: String, default: "加截圖" } }

  update() {
    const files = this.inputTarget.files
    if (!files.length) {
      this.labelTarget.textContent = this.emptyValue
    } else if (!this.inputTarget.multiple) {
      this.labelTarget.textContent = files[0].name
    } else {
      this.labelTarget.textContent = `已揀 ${files.length} 張`
    }
  }
}
