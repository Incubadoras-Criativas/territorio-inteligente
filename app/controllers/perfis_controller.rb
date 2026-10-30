class PerfisController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(perfil_params)
      redirect_to edit_perfil_path, notice: "Perfil atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def perfil_params
    params.expect(user: [ :nome, :login, :avatar ])
  end
end
