import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"
import { camadaDeFundo, pino } from "mapas"

// Mapa só de leitura, com uma lista de pontos: [{ lat, lng, titulo, tipo, url }].
// O mapa fica no target "area" (ou no próprio elemento, se não houver target).
// Opcional: um botão "Perto de mim" e uma área de avisos (target "status").
export default class extends Controller {
  static targets = [ "area", "status" ]

  static values = {
    pontos: Array,
    // Marco Zero do DF, para quando não há nenhum ponto
    centro: { type: Array, default: [ -15.7942, -47.8825 ] }
  }

  connect() {
    const area = this.hasAreaTarget ? this.areaTarget : this.element

    // A roda do mouse e, no celular, o arrastar com um dedo começam desligados:
    // quem está rolando a página não fica preso no mapa
    this.mapa = L.map(area, { scrollWheelZoom: false, dragging: !L.Browser.mobile })
    camadaDeFundo().addTo(this.mapa)

    const marcadores = this.pontosValue.map((ponto) => this.marcador(ponto).addTo(this.mapa))
    this.enquadrar(marcadores)

    // Tocou ou clicou no mapa: a pessoa quer mexer nele
    this.mapa.once("click", () => this.liberar())
  }

  disconnect() {
    this.mapa?.remove()
  }

  // Botão "Perto de mim": a localização só é pedida quando a pessoa toca
  pertoDeMim() {
    if (!navigator.geolocation) {
      this.avisar("Este navegador não informa a localização.")
      return
    }

    this.avisar("Procurando a sua localização…")
    navigator.geolocation.getCurrentPosition(
      (posicao) => this.mostrarOndeEstou(posicao),
                                             () => this.avisar("Não foi possível usar a sua localização."),
                                             { enableHighAccuracy: true, timeout: 20000, maximumAge: 60000 }
    )
  }

  // --- daqui para baixo, só uso interno ---

  marcador({ lat, lng, titulo, tipo, url }) {
    // O nome é digitado por qualquer pessoa: entra como texto, e nunca é interpretado como HTML
    const balao = document.createElement(url ? "a" : "span")
    balao.textContent = titulo
    if (url) balao.href = url

      return L.marker([ lat, lng ], { icon: pino(tipo), title: titulo, keyboard: true }).bindPopup(balao)
  }

  // Nenhum ponto: o Marco Zero. Um ponto: aproxima nele. Vários: mostra todos de uma vez.
  enquadrar(marcadores) {
    if (marcadores.length === 0) {
      this.mapa.setView(this.centroValue, 11)
    } else if (marcadores.length === 1) {
      this.mapa.setView(marcadores[0].getLatLng(), 17)
    } else {
      this.mapa.fitBounds(L.featureGroup(marcadores).getBounds(), { padding: [ 32, 32 ] })
    }
  }

  mostrarOndeEstou(posicao) {
    const aqui = L.latLng(posicao.coords.latitude, posicao.coords.longitude)

    this.voceEstaAqui?.remove()
    this.voceEstaAqui = L.circleMarker(aqui, { radius: 9, weight: 3, className: "voce-esta-aqui" })
    .addTo(this.mapa)
    .bindPopup("Você está aqui")

    this.liberar()
    this.mapa.setView(aqui, 15)
    this.avisar("")
  }

  liberar() {
    this.mapa.dragging.enable()
    this.mapa.scrollWheelZoom.enable()
  }

  avisar(texto) {
    if (this.hasStatusTarget) this.statusTarget.textContent = texto
  }
}
