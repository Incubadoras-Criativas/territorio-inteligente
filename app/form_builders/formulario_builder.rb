# O "f" de todos os formulários do projeto.
# Campo com erro ganha: borda vermelha, mensagem logo abaixo e as marcações
# para o leitor de tela (aria-invalid e aria-describedby).
class FormularioBuilder < ActionView::Helpers::FormBuilder
  CAMPOS = %i[
    text_field email_field password_field search_field
    number_field telephone_field url_field date_field textarea file_field
    ]

  CAMPOS.each do |tipo|
    define_method(tipo) do |atributo, opcoes = {}|
      mensagens = mensagens_de_erro(atributo)
      return super(atributo, opcoes) if mensagens.empty?

      super(atributo, opcoes_com_erro(atributo, opcoes)) + mensagem_de_erro(atributo, mensagens)
    end
  end

  def select(atributo, escolhas = nil, opcoes = {}, html = {}, &bloco)
    mensagens = mensagens_de_erro(atributo)
    return super if mensagens.empty?

    super(atributo, escolhas, opcoes, opcoes_com_erro(atributo, html), &bloco) + mensagem_de_erro(atributo, mensagens)
  end

  # No topo do formulário: avisa que algo deu errado
  def aviso_erros
    return if sem_erros?

    @template.tag.p(I18n.t("formularios.aviso_erros"), class: "aviso-erros", role: "alert")
  end

  # Antes do botão: erros que não pertencem a nenhum campo deste formulário.
  # Assim, nenhum erro fica escondido.
  def erros_restantes
    return if sem_erros?

    restantes = object.errors.reject { |erro| mostrados.include?(erro.attribute) }
    return if restantes.empty?

    @template.tag.ul(class: "erros-restantes") do
      @template.safe_join(restantes.map { |erro| @template.tag.li(erro.full_message) })
    end
  end

  private

  def sem_erros?
    !object.respond_to?(:errors) || object.errors.empty?
  end

  def mostrados
    @mostrados ||= Set.new
  end

  def mensagens_de_erro(atributo)
    return [] unless object.respond_to?(:errors)

    object.errors.full_messages_for(atributo)
  end

  def opcoes_com_erro(atributo, opcoes)
    mostrados << atributo
    aria = (opcoes[:aria] || {}).merge(invalid: true, describedby: "#{field_id(atributo)}_erro")

    opcoes.merge(class: [ opcoes[:class], "com-erro" ].compact.join(" "), aria: aria)
  end

  def mensagem_de_erro(atributo, mensagens)
    @template.tag.p(@template.safe_join(mensagens, @template.tag.br),
                  id: "#{field_id(atributo)}_erro", class: "erro-campo")
  end
end
