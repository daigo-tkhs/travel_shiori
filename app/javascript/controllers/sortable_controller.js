// app/javascript/controllers/sortable_controller.js

import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.sortable = Sortable.create(this.element, {
      group: 'shared-spots', // これにより異なる日の間での移動が可能になります
      animation: 150,
      handle: ".cursor-move",
      onEnd: this.end.bind(this)
    })
  }

  end(event) {
    const id = event.item.dataset.id
    const newIndex = event.newIndex + 1
    // 移動先の要素（event.to）から dayNumber を取得
    const newDayNumber = event.to.dataset.dayNumber

    // URLの :id 部分を実際のIDに置き換え
    const url = this.urlValue.replace(":id", id)

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/vnd.turbo-stream.html", // RailsにTurbo Streamとして返してほしいと伝える
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ 
        spot: { 
          day_number: newDayNumber, // 移動先の日付
          position: newIndex        // 移動先での順番（★ここを追加しました）
        }
      })
    }) 
    .then(async response => {
      if (response.ok) {
        // Railsから送られてきた Turbo Stream (HTML) を受け取って実行する
        const streamResponse = await response.text()
        Turbo.renderStreamMessage(streamResponse)
      } else {
        console.error('スポットの並び替えに失敗しました。ステータス:', response.status);
        // 失敗した場合はリロードして元の状態に戻す
        window.location.reload()
      }
    })
    .catch(error => {
      console.error('通信エラー:', error);
      window.location.reload()
    });
  }
}