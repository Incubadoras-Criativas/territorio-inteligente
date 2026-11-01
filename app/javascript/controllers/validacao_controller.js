import { Controller } from "@hotwired/stimulus"

// Valida os campos no navegador, com as regras do próprio HTML
// (required, type="email", minlength), e mostra o erro no mesmo formato
// do FormularioBuilder: borda, mensagem embaixo do campo e aria-invalid.
// Sem JavaScript, o balão do navegador e a validação do servidor continuam valendo.
export default class extends Controller {
  connect() {
    this.element.querySelectorAll("form").forEach((form) => (form.noValidate = true))
  }

  // Ao sair de um campo: só confere se a pessoa mexeu nele.
  // Quem só passa com o Tab não leva bronca, e o erro do servidor fica até ela corrigir.
  sair(event) {
    const campo = event.target
    if (this.validavel(campo) && campo.dataset.alterado) this.conferir(campo)
  }

  // Ao digitar: marca o campo como alterado e, se ele já tem erro, confere de novo
  digitar(event) {
    const campo = event.target
    if (!this.validavel(campo)) return

      campo.dataset.alterado = "sim"
      if (campo.classList.contains("com-erro")) this.conferir(campo)
  }

  // No envio: confere tudo; se algo estiver errado, não envia
  enviar(event) {
    const campos = [ ...event.target.elements ].filter((campo) => this.validavel(campo))
    const invalidos = campos.filter((campo) => !this.conferir(campo))

    if (invalidos.length > 0) {
      event.preventDefault()
      invalidos[0].focus()
    }
  }

  // Só campos que o navegador sabe validar e que têm id (para ligar à mensagem)
  validavel(campo) {
    return campo.willValidate && campo.id
  }

  conferir(campo) {
    this.conferirTamanho(campo)
    const valido = campo.checkValidity()
    this.limpar(campo)
    if (!valido) this.mostrar(campo, this.mensagem(campo))
      return valido
  }

  // Campos de arquivo com data-tamanho-maximo: confere antes de enviar
  conferirTamanho(campo) {
    const maximo = Number(campo.dataset.tamanhoMaximo)
    if (campo.type !== "file" || !maximo) return

      const grande = [ ...campo.files ].find((arquivo) => arquivo.size > maximo)
      campo.setCustomValidity(grande ? `"${grande.name}" passa de ${maximo / 1024 / 1024} MB.` : "")
  }

  // Ao escolher um arquivo: confere na hora
  escolher(event) {
    if (this.validavel(event.target)) this.conferir(event.target)
  }

  // Mensagens nossas, iguais em qualquer navegador
  mensagem(campo) {
    const regra = campo.validity

    if (regra.valueMissing) return "Preencha este campo."
      if (regra.typeMismatch && campo.type === "email") return "Digite um e-mail válido, como nome@exemplo.com."
        if (regra.tooShort) return `Use pelo menos ${campo.minLength} caracteres.`
          if (regra.customError)
            return campo.validationMessage
  }

  mostrar(campo, texto) {
    const id = `${campo.id}_erro`
    const paragrafo = document.createElement("p")
    paragrafo.id = id
    paragrafo.className = "erro-campo"
    paragrafo.textContent = texto

    campo.classList.add("com-erro")
    campo.setAttribute("aria-invalid", "true")
    campo.setAttribute("aria-describedby", id)
    campo.insertAdjacentElement("afterend", paragrafo)
  }

  limpar(campo) {
    document.getElementById(`${campo.id}_erro`)?.remove()
    campo.classList.remove("com-erro")
    campo.removeAttribute("aria-invalid")
    campo.removeAttribute("aria-describedby")
  }
}
