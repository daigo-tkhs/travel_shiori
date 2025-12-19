import { Controller } from "@hotwired/stimulus"
import debounce from "debounce"

export default class extends Controller {
  static targets = [ "address", "latitude", "longitude", "submit" ] 
  static values = { apiKey: String }

  connect() {
    this.geocodeDebounced = debounce(this.geocode, 800)
    
    // ▼▼▼ 修正: Mapコントローラーと同じ設定でAPIを読み込む ▼▼▼
    this.loadGoogleMaps()
    
    // 初期状態はボタン無効（緯度経度がないため）
    this.toggleSubmitButton()
  }

  // ▼▼▼ 追加: API読み込み処理（これが無いと動きません） ▼▼▼
  loadGoogleMaps() {
    if (window.google && window.google.maps) return

    const existingScript = document.querySelector(`script[src*="maps.googleapis.com/maps/api/js"]`)
    if (existingScript) return

    const script = document.createElement("script")
    // v=weekly と libraries=places,marker を指定して map_controller.js と統一
    script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&libraries=places,marker&loading=async&v=weekly`
    script.async = true
    script.defer = true
    document.head.appendChild(script)
  }

  // ▼▼▼ 修正: fetch ではなく google.maps.Geocoder を使用 ▼▼▼
  async geocode() {
    const address = this.addressTarget.value
    this.toggleSubmitButton(false)

    if (address.length < 2) {
      this.clearCoords()
      return
    }

    if (!window.google || !window.google.maps) {
      console.warn("Google Maps API not loaded yet.")
      return
    }

    const geocoder = new google.maps.Geocoder()

    try {
      const result = await geocoder.geocode({ address: address })
      
      if (result.results && result.results.length > 0) {
        const location = result.results[0].geometry.location
        this.latitudeTarget.value = location.lat()
        this.longitudeTarget.value = location.lng()
      } else {
        this.clearCoords()
      }
    } catch (error) {
      console.error("Geocoding failed:", error)
      this.clearCoords()
    } finally {
      this.toggleSubmitButton()
    }
  }
  
  clearCoords() {
    this.latitudeTarget.value = ''
    this.longitudeTarget.value = ''
    this.toggleSubmitButton()
  }

  toggleSubmitButton(forceState = null) {
    if (!this.hasSubmitTarget) return

    const coordsPresent = this.latitudeTarget.value && this.longitudeTarget.value
    let isEnabled

    if (forceState !== null) {
      isEnabled = forceState
    } else {
      isEnabled = coordsPresent
    }

    this.submitTarget.disabled = !isEnabled
    
    if (isEnabled) {
      this.submitTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.submitTarget.classList.add('cursor-pointer')
    } else {
      this.submitTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.submitTarget.classList.remove('cursor-pointer')
    }
  }
}