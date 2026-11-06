import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

// Mapa com pino arrastável, ligado aos campos de latitude e longitude.
// O botão "Usar minha localização" pede as coordenadas ao GPS do celular.
// Sem JavaScript, os campos continuam lá para digitar.
export default class extends Controller {
  static targets = [ "latitude", "longitude", "mapa", "status" ]

  // Centro de Ceilândia, para quando ainda não há ponto
  static values = { centro: { type: Array, default: [ -15.8166, -48.1060 ] } }

  connect() {
    const ponto = this.pontoDosCampos()

    this.mapa = L.map(this.mapaTarget).setView(ponto || this.centroValue, ponto ? 17 : 13)
    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(this.mapa)

    if (ponto) this.colocarPino(ponto)

      // Tocar no mapa também posiciona o pino
      this.mapa.on("click", (evento) => this.moverPara(evento.latlng))
  }

  disconnect() {
    this.mapa?.remove()
  }

  // Botão "Usar minha localização"
  localizar() {
    if (!navigator.geolocation) {
      this.avisar("Este navegador não informa a localização. Toque no mapa para marcar o ponto.")
      return
    }

    this.avisar("Procurando a sua localização…")
    navigator.geolocation.getCurrentPosition(
      (posicao) => this.encontrou(posicao),
                                             (erro) => this.falhou(erro),
                                             { enableHighAccuracy: true, timeout: 20000, maximumAge: 0 }
    )
  }

  // Quando alguém digita nos campos, o pino acompanha
  digitou() {
    const ponto = this.pontoDosCampos()
    if (!ponto) return

      this.colocarPino(ponto)
      this.mapa.setView(ponto)
  }

  // --- daqui para baixo, só uso interno ---

  encontrou(posicao) {
    const { latitude, longitude, accuracy } = posicao.coords
    this.moverPara(L.latLng(latitude, longitude))
    this.mapa.setView([ latitude, longitude ], 18)

    this.precisao?.remove()
    this.precisao = L.circle([ latitude, longitude ], { radius: accuracy, weight: 1 }).addTo(this.mapa)

    this.avisar(`Localização encontrada, com precisão de uns ${Math.round(accuracy)} m. Se precisar, arraste o pino até o lugar exato.`)
  }

  falhou(erro) {
    const mensagens = {
      1: "Você não permitiu o uso da localização. Toque no mapa para marcar o ponto.",
      2: "Não foi possível descobrir a localização agora. Tente de novo ou toque no mapa.",
      3: "A localização demorou demais. Tente de novo, de preferência ao ar livre."
    }
    this.avisar(mensagens[erro.code] || "Não foi possível usar a localização.")
  }

  moverPara(latlng) {
    this.colocarPino(latlng)
    this.preencherCampos(latlng)
  }

  colocarPino(latlng) {
    if (this.pino) {
      this.pino.setLatLng(latlng)
      return
    }

    this.pino = L.marker(latlng, { draggable: true, icon: this.icone(), keyboard: true, title: "Local da academia" })
    .addTo(this.mapa)
    this.pino.on("dragend", () => this.preencherCampos(this.pino.getLatLng()))
  }

  preencherCampos(latlng) {
    this.latitudeTarget.value = latlng.lat.toFixed(6)
    this.longitudeTarget.value = latlng.lng.toFixed(6)
  }

  pontoDosCampos() {
    const lat = parseFloat(this.latitudeTarget.value)
    const lng = parseFloat(this.longitudeTarget.value)
    return Number.isFinite(lat) && Number.isFinite(lng) ? L.latLng(lat, lng) : null
  }

  // Pino feito em CSS: dispensa as imagens do Leaflet
  icone() {
    return L.divIcon({ className: "pino", iconSize: [ 28, 28 ], iconAnchor: [ 14, 28 ] })
  }

  avisar(texto) {
    this.statusTarget.textContent = texto
  }
}
