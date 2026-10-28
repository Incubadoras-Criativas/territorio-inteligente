module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :exigir_admin

    private

    def exigir_admin
      redirect_to root_path, alert: "Acesso restrito a administradores." unless current_user.admin?
    end
  end
end
