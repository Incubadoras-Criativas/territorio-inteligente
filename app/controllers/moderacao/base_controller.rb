# Base dos controllers de moderação: só moderadores e admin entram
module Moderacao
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :exigir_moderacao

    private

    def exigir_moderacao
      redirect_to root_path, alert: "Esta página é só para quem modera." unless current_user.pode_moderar?
    end
  end
end
