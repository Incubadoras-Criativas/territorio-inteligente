module Moderacao
  class FotosController < BaseController
    before_action :carregar_foto

    def aprovar
      @foto.aprovar!(por: current_user)
      responder "Foto aprovada."
    end

    def recusar
      @foto.recusar!(por: current_user)
      responder "Foto recusada."
    end

    private

    # Só as pendentes: se outra pessoa já moderou, a resposta é 404
    def carregar_foto
      @foto = Foto.pendente.find(params[:id])
    end

    # Com Turbo, a foto some da lista sem recarregar; sem ele, volta para a página
    def responder(aviso)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@foto) }
        format.html { redirect_to moderacao_path, notice: aviso }
      end
    end
  end
end
