import { Controller } from "@hotwired/stimulus"

// Envia o formulário assim que a pessoa escolhe os arquivos
export default class extends Controller {
  enviar() {
    this.element.requestSubmit()
  }
}
