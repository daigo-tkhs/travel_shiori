import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "spotImage"]
  static values = { apiKey: String, markers: Array }

  connect() {
    this.loadGoogleMaps()
  }

  loadGoogleMaps() {
    if (window.google && window.google.maps) {
      this.initMap()
      return
    }
    const script = document.createElement("script")
    // v=weekly で安定版を読み込みます
    script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&libraries=places&v=weekly`
    script.async = true
    script.defer = true
    script.onload = () => this.initMap()
    document.head.appendChild(script)
  }

  initMap() {
    if (!this.hasContainerTarget) return

    // ズレを防ぐため、シンプルな設定にします
    const mapOptions = {
      center: { lat: 35.6812, lng: 139.7671 },
      zoom: 12,
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: false
    }

    // importLibraryを使わず、直接 new google.maps.Map します
    this.map = new google.maps.Map(this.containerTarget, mapOptions)
    this.addMarkers()
    this.loadSpotPhotos()
  }

  addMarkers() {
    if (!this.markersValue || this.markersValue.length === 0) return
    const bounds = new google.maps.LatLngBounds()

    this.markersValue.forEach((markerData, index) => {
      const position = { lat: parseFloat(markerData.lat), lng: parseFloat(markerData.lng) }
      
      // 標準の Marker を使用（これが一番ズレません）
      new google.maps.Marker({
        position: position,
        map: this.map,
        title: markerData.title,
        label: {
          text: `${index + 1}`,
          color: "white",
          fontWeight: "bold"
        },
        // アイコンの設定（青いピンに見せる）
        icon: {
            path: google.maps.SymbolPath.BACKWARD_CLOSED_ARROW,
            scale: 6,
            fillColor: "#2563EB",
            fillOpacity: 1,
            strokeWeight: 2,
            strokeColor: "#1E40AF" 
        }
      })
      bounds.extend(position)
    })

    this.map.fitBounds(bounds)
    
    if (this.markersValue.length === 1) {
      google.maps.event.addListenerOnce(this.map, "idle", () => {
        this.map.setZoom(15)
      })
    }
  }

  loadSpotPhotos() {
    if (!this.hasSpotImageTarget) return

    // Google Places サービスを初期化
    const service = new google.maps.places.PlacesService(this.map)

    this.spotImageTargets.forEach(target => {
      const spotName = target.dataset.spotName
      if (!spotName) return

      // スポット名で写真を検索
      service.findPlaceFromQuery({
        query: spotName,
        fields: ['photos']
      }, (results, status) => {
        if (status === google.maps.places.PlacesServiceStatus.OK && results && results[0].photos) {
          const photoUrl = results[0].photos[0].getUrl({ maxWidth: 400 })
          this.injectPhoto(target, photoUrl)
        }
      })
    })
  }

  injectPhoto(targetElement, url) {
    const img = document.createElement('img')
    img.src = url
    img.className = "w-full h-full object-cover transition-opacity duration-500 opacity-0"
    img.onload = () => img.classList.remove('opacity-0')
    targetElement.innerHTML = ''
    targetElement.appendChild(img)
  }
}