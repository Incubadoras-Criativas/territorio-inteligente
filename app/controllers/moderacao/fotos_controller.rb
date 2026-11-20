module Moderacao
  class FotosController < BaseController
    before_action :carregar_foto

    def aprovar
      @foto.aprovar!(por: current_user)
      responder @foto, "Foto aprovada."
    end

    def recusar
      @foto.recusar!(por: current_user)
      responder @foto, "Foto recusada."
    end

    private

    # Só as pendentes: se outra pessoa já moderou, a resposta é 404
    def carregar_foto
      @foto = Foto.pendente.find(params[:id])
    end
  end
end
