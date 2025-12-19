import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "spotImage"] // spotImageターゲットを追加
  static values = {
    apiKey: String,
    markers: Array
  }

  connect() {
    this.loadGoogleMaps()
  }

  loadGoogleMaps() {
    // 既にAPIが読み込まれているかチェック
    if (window.google && window.google.maps) {
      this.initMap()
      return
    }

    // 重複読み込み防止: 既にスクリプトタグがあるかチェック
    const existingScript = document.querySelector(`script[src*="maps.googleapis.com/maps/api/js"]`)
    if (existingScript) {
      existingScript.addEventListener("load", () => this.initMap())
      return
    }

    // APIスクリプトを動的に生成
    const script = document.createElement("script")
    // placesライブラリとmarkerライブラリを追加
    script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&libraries=places,marker&loading=async`
    script.async = true
    script.defer = true
    script.onload = () => this.initMap()
    document.head.appendChild(script)
  }

  async initMap() {
    if (!this.hasContainerTarget) return

    // マップ初期化 (mapIdは必須。DEMO_MAP_IDを使用)
    const { Map } = await google.maps.importLibrary("maps")
    const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker")

    const mapOptions = {
      center: { lat: 35.6812, lng: 139.7671 },
      zoom: 12,
      mapId: "DEMO_MAP_ID", // AdvancedMarkerには必須
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: false
    }

    this.map = new Map(this.containerTarget, mapOptions)
    
    // マーカー追加
    this.addMarkers(AdvancedMarkerElement, PinElement)
    
    // 写真取得処理の開始
    this.loadSpotPhotos()
  }

  addMarkers(AdvancedMarkerElement, PinElement) {
    if (!this.markersValue || this.markersValue.length === 0) return

    const bounds = new google.maps.LatLngBounds()

    this.markersValue.forEach((markerData, index) => {
      const position = { lat: parseFloat(markerData.lat), lng: parseFloat(markerData.lng) }
      
      // ピンのデザイン設定
      const pin = new PinElement({
        glyph: `${index + 1}`,
        background: "#2563EB", // Blue-600
        borderColor: "#1E40AF",
        glyphColor: "white",
      })

      new AdvancedMarkerElement({
        position: position,
        map: this.map,
        title: markerData.title,
        content: pin.element
      })

      bounds.extend(position)
    })

    this.map.fitBounds(bounds)
    
    if (this.markersValue.length === 1) {
      // 1点だけの場合、少し引いた位置で表示しないと近すぎる
      const listener = google.maps.event.addListener(this.map, "idle", () => { 
        this.map.setZoom(15) 
        google.maps.event.removeListener(listener)
      })
    }
  }

  // --- 写真取得機能 ---
  loadSpotPhotos() {
    if (!this.hasSpotImageTarget) return

    // PlacesServiceの初期化（マップがないと動かないためここで初期化）
    const service = new google.maps.places.PlacesService(this.map)

    this.spotImageTargets.forEach(target => {
      const spotName = target.dataset.spotName
      if (!spotName) return

      const request = {
        query: spotName,
        fields: ['photos'] // 写真のみ取得
      }

      service.findPlaceFromQuery(request, (results, status) => {
        if (status === google.maps.places.PlacesServiceStatus.OK && results && results[0].photos) {
          const photoUrl = results[0].photos[0].getUrl({ maxWidth: 200, maxHeight: 200 })
          this.injectPhoto(target, photoUrl)
        }
      })
    })
  }

  injectPhoto(targetElement, url) {
    // 既存のプレースホルダーアイコンを隠す
    const placeholder = targetElement.querySelector('.placeholder-icon')
    if (placeholder) placeholder.style.display = 'none'

    // 画像要素を作成して挿入
    const img = document.createElement('img')
    img.src = url
    img.className = "w-full h-full object-cover transition-opacity duration-500 opacity-0"
    img.onload = () => img.classList.remove('opacity-0')
    
    targetElement.appendChild(img)
  }
}