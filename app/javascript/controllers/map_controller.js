import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "spotImage"] 
  static values = { apiKey: String, markers: Array }

  connect() {
    this.loadGoogleMaps()
  }

  spotImageTargetConnected(element) {
    this.loadPhotoForElement(element)
  }

  loadGoogleMaps() {
    if (window.google && window.google.maps && window.google.maps.marker) {
      this.initMap()
      return
    }

    const script = document.createElement("script")
    script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&libraries=places,marker&v=weekly`
    script.async = true
    script.defer = true
    script.onload = () => this.initMap()
    document.head.appendChild(script)
  }

  async initMap() {
    if (!this.hasContainerTarget) return

    if (!google.maps.marker) {
        try {
            await google.maps.importLibrary("marker");
        } catch (e) {
            console.error("Marker library load failed:", e);
            return;
        }
    }

    const mapOptions = {
      center: { lat: 35.6812, lng: 139.7671 },
      zoom: 12,
      mapId: "DEMO_MAP_ID",
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: false
    }

    this.map = new google.maps.Map(this.containerTarget, mapOptions)
    this.addMarkers()
  }

  async addMarkers() {
    if (!this.markersValue || this.markersValue.length === 0) return
    
    const bounds = new google.maps.LatLngBounds()
    const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker")

    this.markersValue.forEach((markerData, index) => {
      const lat = parseFloat(markerData.lat)
      const lng = parseFloat(markerData.lng)
      if (isNaN(lat) || isNaN(lng)) return

      const position = { lat: lat, lng: lng }
      const pin = new PinElement({
        glyphText: `${index + 1}`,
        background: "#2563EB",
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
      const listener = google.maps.event.addListener(this.map, "idle", () => {
        this.map.setZoom(15)
        google.maps.event.removeListener(listener)
      })
    }
  }

  async loadPhotoForElement(target) {
    const spotName = target.dataset.spotName
    if (!spotName) return

    if (target.querySelector('img')) return

    let Place;
    try {
        const lib = await google.maps.importLibrary("places");
        Place = lib.Place;
    } catch (e) {
        console.error("Places library import failed:", e);
        return;
    }

    try {
      const { places } = await Place.searchByText({
          textQuery: spotName,
          fields: ['photos'],
          maxResultCount: 1,
      });

      if (places && places.length > 0 && places[0].photos && places[0].photos.length > 0) {
          const photo = places[0].photos[0];
          const photoUrl = photo.getURI({ maxWidth: 400 });
          this.injectPhoto(target, photoUrl);
      }
    } catch (error) {
    }
  }

  injectPhoto(targetElement, url) {
    const img = document.createElement('img')
    img.src = url
    img.className = "w-full h-full object-cover transition-opacity duration-500 opacity-0 rounded-md"
    img.onload = () => img.classList.remove('opacity-0')
    targetElement.innerHTML = ''
    targetElement.appendChild(img)
  }
}