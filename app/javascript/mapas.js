import * as L from "leaflet"

// O que todo mapa do projeto usa: o mapa de fundo e o pino.

// O mapa de fundo do OpenStreetMap, com o crédito que a licença exige
export function camadaDeFundo() {
  return L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
  })
}

// Pino feito em CSS: dispensa as imagens do Leaflet.
// O tipo vira uma classe (pino-academia, pino-cultura...), para cada tipo ter a sua cor no futuro.
export function pino(tipo = "academia") {
  return L.divIcon({
    className: `pino pino-${tipo}`,
    iconSize: [ 28, 28 ],
    iconAnchor: [ 14, 28 ],
    popupAnchor: [ 0, -28 ]
  })
}
