// app/javascript/controllers/geocoding_controller.js

import { Controller } from "@hotwired/stimulus"
import debounce from "debounce"

export default class extends Controller {
  // ★修正箇所: "submit" ターゲットを追加
  static targets = [ "address", "latitude", "longitude", "submit" ] 
  
  static values = { apiKey: String }

  connect() {
    console.log("Geocoding Controller connected.")
    this.geocodeDebounced = debounce(this.geocode, 800)
    
    // ★修正箇所: 初期状態ではボタンを無効化
    this.toggleSubmitButton()
  }

  // ジオコーディングを実行し、緯度経度を取得する
  geocode() {
    const address = this.addressTarget.value
    
    // 検索中はボタンを無効化
    this.toggleSubmitButton(false) 

    if (address.length < 5) {
      this.clearCoords()
      this.toggleSubmitButton()
      return
    }

    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${this.apiKeyValue}`

    fetch(url)
      .then(response => response.json())
      .then(data => {
        if (data.status === 'OK') {
          const location = data.results[0].geometry.location
          this.latitudeTarget.value = location.lat
          this.longitudeTarget.value = location.lng
        } else {
          // ZERO_RESULTS やその他の API エラーの場合も座標をクリア
          this.clearCoords() 
        }
        
        // ★修正箇所: 結果に応じてボタンを有効化/無効化
        this.toggleSubmitButton() 
      })
      .catch(error => {
        console.error('Geocoding API Error:', error)
        this.clearCoords()
        this.toggleSubmitButton(false) // 通信エラー時は無効のまま
      })
  }
  
  // 緯度経度フィールドをクリアする
  clearCoords() {
    this.latitudeTarget.value = ''
    this.longitudeTarget.value = ''
    this.toggleSubmitButton()
  }

  // ★新規追加: 送信ボタンの有効/無効を制御するメソッド
  toggleSubmitButton(forceState = null) {
    // 緯度経度が両方存在するかどうか
    const coordsPresent = this.latitudeTarget.value && this.longitudeTarget.value
    let shouldBeEnabled;

    if (forceState !== null) {
      // 状態が強制されている場合 (例: 検索中、通信エラーなど)
      shouldBeEnabled = forceState;
    } else {
      // 緯度経度が揃っている場合のみ有効
      shouldBeEnabled = coordsPresent;
    }

    if (this.submitTarget) {
      this.submitTarget.disabled = !shouldBeEnabled;
      
      // 見た目の制御 (TailwindCSSを使用していると仮定)
      if (shouldBeEnabled) {
        this.submitTarget.classList.remove('opacity-50', 'cursor-not-allowed');
      } else {
        this.submitTarget.classList.add('opacity-50', 'cursor-not-allowed');
      }
    }
  }
}