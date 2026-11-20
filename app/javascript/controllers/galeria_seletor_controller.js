import { Controller } from "@hotwired/stimulus"

// Abre a galeria numa janela e mostra quantas imagens foram escolhidas
export default class extends Controller {
  static targets = [ "janela", "resumo" ]

  connect() {
    this.atualizar()
  }

  abrir() {
    this.janelaTarget.showModal()
  }

  fechar() {
    this.janelaTarget.close()
  }

  atualizar() {
    const total = this.janelaTarget.querySelectorAll("input[type=checkbox]:checked").length

    this.resumoTarget.textContent =
    total === 0 ? "" :
    total === 1 ? "1 foto escolhida da galeria." :
    `${total} fotos escolhidas da galeria.`
  }
}
