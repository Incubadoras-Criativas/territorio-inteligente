class EquipamentosController < ApplicationController
  def index
    @equipamentos = equipamentos_permitidos.with_attached_capa.order(:nome)
  end

  def show
    @equipamento = equipamentos_permitidos.find_by!(slug: params[:slug])
  end

  private

  # O admin vê também os rascunhos; o público, só os visíveis
  def equipamentos_permitidos
    current_user&.admin? ? Equipamento.all : Equipamento.visiveis
  end
end
