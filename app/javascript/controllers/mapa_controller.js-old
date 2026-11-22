import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"
import { camadaDeFundo, pino } from "mapas"

// Mapa só de leitura, com uma lista de pontos: [{ lat, lng, titulo, tipo }].
// Hoje, a academia. Depois, também os equipamentos do entorno.
export default class extends Controller {
  static values = { pontos: Array }

  connect() {
    // A roda do mouse e, no celular, o arrastar com um dedo começam desligados:
    // quem está rolando a página não fica preso no mapa
    this.mapa = L.map(this.element, { scrollWheelZoom: false, dragging: !L.Browser.mobile })
    camadaDeFundo().addTo(this.mapa)

    const marcadores = this.pontosValue.map((ponto) => this.marcador(ponto).addTo(this.mapa))
    this.enquadrar(marcadores)

    // Tocou ou clicou no mapa: a pessoa quer mexer nele
    this.mapa.once("click", () => {
      this.mapa.dragging.enable()
      this.mapa.scrollWheelZoom.enable()
    })
  }

  disconnect() {
    this.mapa?.remove()
  }

  // --- daqui para baixo, só uso interno ---

  marcador({ lat, lng, titulo, tipo }) {
    // O nome é digitado por qualquer pessoa: entra como texto, e nunca é interpretado como HTML
    const balao = document.createElement("span")
    balao.textContent = titulo

    return L.marker([ lat, lng ], { icon: pino(tipo), title: titulo, keyboard: true }).bindPopup(balao)
  }

  // Um ponto: aproxima nele. Vários: mostra todos de uma vez.
  enquadrar(marcadores) {
    if (marcadores.length === 1) {
      this.mapa.setView(marcadores[0].getLatLng(), 17)
    } else if (marcadores.length > 1) {
      this.mapa.fitBounds(L.featureGroup(marcadores).getBounds(), { padding: [ 32, 32 ] })
    }
  }
}
