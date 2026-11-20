# Registros que recebem fotos escolhidas da galeria.
module Fotografavel
  extend ActiveSupport::Concern

  included do
    has_many :fotos, as: :fotografavel, dependent: :destroy, autosave: true
  end

  # Visitante: só as aprovadas. Quem modera: todas. Os demais: as aprovadas e as próprias.
  # Filtra as fotos já carregadas: com includes, não consulta o banco de novo.
  def fotos_visiveis_para(user)
    fotos.select do |foto|
      foto.aprovada? || user&.pode_moderar? || foto.autor_id == user&.id
    end
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

  # Marca para remover, no save, as fotos que a pessoa pode remover. As outras são ignoradas.
  def remover_fotos(ids, por:)
    fotos.select { |foto| ids.include?(foto.id) && foto.removivel_por?(por) }
    .each(&:mark_for_destruction)
  end

  # A foto marcada como capa ou, se não houver, a primeira aprovada.
  # Trabalha com as fotos já carregadas: na lista, não faz uma consulta por item.
  def foto_de_capa
    aprovadas = fotos.select(&:aprovada?)
    aprovadas.find(&:capa?) || aprovadas.min_by(&:created_at)
  end
end
