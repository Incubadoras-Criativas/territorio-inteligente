module Moderacao
  class PainelController < BaseController
    def index
      @fotos = Foto.pendente.order(:created_at)
      .includes(:autor, :fotografavel, imagem: { arquivo_attachment: :blob })

      @academias = Academia.rascunhos.order(:created_at).includes(:autor)
      @observacoes = Observacao.rascunhos.order(:created_at).includes(:autor, :academia)
    end
  end
end
