# Registros que recebem fotos escolhidas da galeria.
module Fotografavel
  extend ActiveSupport::Concern

  included do
    has_many :fotos, as: :fotografavel, dependent: :destroy
  end

  # Visitante: só as aprovadas. Quem modera: todas. Os demais: as aprovadas e as próprias.
  def fotos_visiveis_para(user)
    return fotos.aprovada unless user
    return fotos if user.pode_moderar?

    fotos.aprovada.or(fotos.where(autor: user))
  end

  # Anexa imagens da galeria de quem está editando. Funciona em registros novos e já salvos:
  # as fotos são gravadas junto com o registro, no save.
  def anexar_imagens(imagens, por:)
    aprovada = por.pode_moderar?
    ja_anexadas = fotos.map(&:imagem_id)

    imagens.reject { |imagem| ja_anexadas.include?(imagem.id) }.each do |imagem|
      fotos.build(imagem: imagem, autor: por,
                  situacao: aprovada ? :aprovada : :pendente,
                  moderador: (por if aprovada), moderado_em: (Time.current if aprovada))
    end
  end
end
