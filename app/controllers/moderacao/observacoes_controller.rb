module Moderacao
  class ObservacoesController < BaseController
    def publicar
      observacao = Observacao.rascunhos.find(params[:id])

      if observacao.publicar
        responder observacao, "Observação publicada."
      else
        redirect_to moderacao_path, status: :see_other,
                    alert: "Não foi possível publicar: #{observacao.errors.full_messages.to_sentence}"
      end
    end
  end
end
