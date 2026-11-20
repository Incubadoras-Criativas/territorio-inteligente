import { Controller } from "@hotwired/stimulus"

// Abre a galeria numa janela e mostra, no formulário, as imagens escolhidas.
// Um toque numa miniatura escolhida a desmarca.
export default class extends Controller {
  static targets = [ "janela", "resumo", "previa" ]

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
    const marcadas = [ ...this.janelaTarget.querySelectorAll("input[type=checkbox]:checked") ]

    this.previaTarget.replaceChildren(...marcadas.map((caixa) => this.miniatura(caixa)))
    this.resumoTarget.textContent =
    marcadas.length === 0 ? "" :
    marcadas.length === 1 ? "1 foto escolhida. Ela será anexada ao salvar." :
    `${marcadas.length} fotos escolhidas. Elas serão anexadas ao salvar.`
  }

  // Uma cópia da miniatura da janela, que desmarca a imagem ao ser tocada
  miniatura(caixa) {
    const botao = document.createElement("button")
    botao.type = "button"
    botao.className = "previa-foto"
    botao.setAttribute("aria-label", "Desmarcar esta foto")
    botao.append(caixa.closest("label").querySelector("img").cloneNode())
    botao.addEventListener("click", () => {
      caixa.checked = false
      this.atualizar()
    })
    return botao
  }
}
