import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // これがコンソールに出れば、HTMLとの紐付けは成功です
    console.log("Flash controller connected!");

    // 5秒後に自動で消すタイマー設定
    this.timeout = setTimeout(() => {
      this.dismiss();
    }, 5000);
  }

  // ×ボタンが押されたとき、またはタイマーで呼ばれる
  dismiss() {
    console.log("Dismissing flash message...");
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    // フェードアウトアニメーションのクラスを追加
    this.element.classList.add("opacity-0", "-translate-y-4");
    
    // アニメーションが終わる0.5秒後に要素を削除
    setTimeout(() => {
      this.element.remove();
    }, 500);
  }

  // コントローラーが外れる（ページ遷移など）時にタイマーを掃除
  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }
}