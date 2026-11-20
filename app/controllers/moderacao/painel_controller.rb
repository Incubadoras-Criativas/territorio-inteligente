module Moderacao
  class PainelController < BaseController
    def index
      @fotos = Foto.pendente.order(:created_at)
      .includes(:autor, :fotografavel, imagem: { arquivo_attachment: :blob })
    end
  end
end
