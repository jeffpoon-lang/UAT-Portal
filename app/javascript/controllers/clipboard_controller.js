import { Controller } from "@hotwired/stimulus"

// Copies the text of the source target (a <code> or a <textarea>) and
// briefly changes the button label to say so.
export default class extends Controller {
  static targets = ["source", "label"]

  async copy() {
    const text = this.sourceTarget.value ?? this.sourceTarget.textContent
    try {
      await navigator.clipboard.writeText(text.trim())
      this.flash("已複製")
    } catch {
      // No clipboard permission: select the text so it can be copied by hand
      if (this.sourceTarget.select) this.sourceTarget.select()
      this.flash("請手動複製")
    }
  }

  flash(text) {
    if (!this.hasLabelTarget) return
    this.original ??= this.labelTarget.textContent
    this.labelTarget.textContent = text
    clearTimeout(this.timer)
    this.timer = setTimeout(() => (this.labelTarget.textContent = this.original), 2000)
  }
}
