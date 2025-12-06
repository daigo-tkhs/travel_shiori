import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.sortable = Sortable.create(this.element, {
      group: 'shared-spots', // ★追加: 同じグループ名同士で移動可能にする
      animation: 150,
      handle: ".cursor-move",
      onEnd: this.end.bind(this)
    })
  }

  end(event) {
    const id = event.item.dataset.id
    const newIndex = event.newIndex + 1
    // ★追加: 移動先のリスト（コンテナ）から data-day-number を取得
    const newDayNumber = event.to.dataset.dayNumber

    fetch(this.urlValue.replace(":id", id), {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ 
        position: newIndex,
        day_number: newDayNumber // ★追加: 日数も送信
      })
    })
  }
}