import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
    console.log("Flash controller connected!") 

    // 5秒後に削除アニメーションを開始
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, 5000)
  }

  dismiss() {
    console.log("Dismiss clicked") 

    clearTimeout(this.timeout)
    // ふわっと消えるアニメーション
    this.element.classList.add("opacity-0", "translate-y-[-20px]")
    this.element.classList.remove("opacity-100", "translate-y-0")
    
    // アニメーション完了後（0.5秒後）に要素を削除
    setTimeout(() => {
      this.element.remove()
    }, 500)
  }
}