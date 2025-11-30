import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    apiKey: String,
    markers: Array
  }

  connect() {
    // 既にGoogle Maps APIが読み込まれているかチェック
    if (typeof google !== "undefined" && typeof google.maps !== "undefined") {
      this.initMap()
    } else {
      this.loadGoogleMaps()
    }
  }

  loadGoogleMaps() {
    // APIスクリプトがまだ存在しない場合のみ追加
    const existingScript = document.querySelector("script[src*='maps.googleapis.com/maps/api/js']")
    
    if (!existingScript) {
      const script = document.createElement("script")
      // callback=initMap で読み込み完了後にグローバル関数を呼ぶ
      script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&callback=initMap`
      script.async = true
      script.defer = true
      document.head.appendChild(script)

      // コールバック関数をウィンドウオブジェクトに登録
      window.initMap = () => {
        this.initMap()
      }
    } else {
      // 既に読み込み処理が走っている場合は少し待って再試行
      setTimeout(() => this.connect(), 100)
    }
  }

  initMap() {
    if (!this.hasContainerTarget) return

    // 地図の初期表示（スポットがない場合は東京駅周辺をデフォルトに）
    const defaultCenter = { lat: 35.681236, lng: 139.767125 } 
    
    // スポットがある場合は最初のスポットを中心に、なければデフォルト
    const center = this.markersValue.length > 0 
      ? { lat: this.markersValue[0].lat, lng: this.markersValue[0].lng }
      : defaultCenter

    const map = new google.maps.Map(this.containerTarget, {
      center: center,
      zoom: 12,
    })

    // マーカー（ピン）を設置
    this.markersValue.forEach((markerData) => {
      const marker = new google.maps.Marker({
        position: { lat: markerData.lat, lng: markerData.lng },
        map: map,
        title: markerData.title,
      })

      // マーカークリック時に名前を表示するウィンドウ
      const infoWindow = new google.maps.InfoWindow({
        content: `<div class="p-2 text-gray-900 font-bold">${markerData.title}</div>`
      })

      marker.addListener("click", () => {
        infoWindow.open(map, marker)
      })
    })
  }
}