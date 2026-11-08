import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }

// Fotos entram só pelo campo de fotos, com o termo de consentimento.
// O Trix aceitaria imagens arrastadas para o texto, por fora dessas regras.
document.addEventListener("trix-file-accept", (evento) => evento.preventDefault())
