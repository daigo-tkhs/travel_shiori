import { Controller } from "@hotwired/stimulus"
import debounce from "debounce"

export default class extends Controller {
  static targets = [ "address", "latitude", "longitude", "submit" ] 
  // HTML側でAPIキーを読み込むため、ここでapiKeyの値を受け取る必要は基本なくなりますが、
  // 他のロジックで使う可能性も考慮し、定義は残しても無害です。
  static values = { apiKey: String }

  connect() {
    this.geocodeDebounced = debounce(this.geocode, 800)
    // this.loadGoogleMaps() ← ★削除: HTML側で読み込むため不要
    this.toggleSubmitButton()
  }

  async geocode() {
    const address = this.addressTarget.value
    this.toggleSubmitButton(false)

    if (address.length < 2) {
      this.clearCoords()
      return
    }

    // Google Maps APIがまだ読み込まれていない場合のガード
    if (!window.google || !window.google.maps) {
      console.warn("Google Maps API is not loaded yet.")
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
    let isEnabled = forceState !== null ? forceState : coordsPresent

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