class EquipamentosController < ApplicationController
  def index
    @equipamentos = equipamentos_permitidos.order(:nome).includes(fotos: { imagem: { arquivo_attachment: :blob } })
  end

  def show
    @equipamento = equipamentos_permitidos.includes(fotos: { imagem: { arquivo_attachment: :blob } })
    .find_by!(slug: params[:slug])
  end

  private

  # O admin vê também os rascunhos; o público, só os visíveis
  def equipamentos_permitidos
    current_user&.admin? ? Equipamento.all : Equipamento.visiveis
  end
end
