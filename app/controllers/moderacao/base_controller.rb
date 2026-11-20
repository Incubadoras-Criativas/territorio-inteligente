module Moderacao
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :exigir_moderacao

    private

    def exigir_moderacao
      redirect_to root_path, alert: "Esta página é só para quem modera." unless current_user.pode_moderar?
    end

    # Com Turbo, o item some da lista sem recarregar; sem ele, volta para a página
    def responder(registro, aviso)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(registro) }
        format.html { redirect_to moderacao_path, notice: aviso }
      end
    end
  end
end
