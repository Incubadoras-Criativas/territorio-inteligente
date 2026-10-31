class EquipamentosController < ApplicationController
  def index
    @equipamentos = Equipamento.order(:nome)
  end

  def show
    @equipamento = Equipamento.find_by!(slug: params[:slug])
  end
end
