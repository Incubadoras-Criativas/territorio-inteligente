module Moderacao
  class AcademiasController < BaseController
    def publicar
      academia = Academia.rascunhos.find(params[:id])

      if academia.publicar
        responder academia, "Academia publicada."
      else
        redirect_to moderacao_path, status: :see_other,
                    alert: "Não foi possível publicar: #{academia.errors.full_messages.to_sentence}"
      end
    end
  end
end
