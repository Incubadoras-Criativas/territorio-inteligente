class Academia < ApplicationRecord
  belongs_to :territorio
  belongs_to :autor, class_name: "User", optional: true

  has_many :academia_categorias, dependent: :destroy
  has_many :categorias, through: :academia_categorias
  has_many :academia_equipamentos, dependent: :destroy, autosave: true
  has_many :equipamentos, through: :academia_equipamentos

  scope :visiveis, -> { where(visivel: true) }


  validates :categorias, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  # Nome é opcional: na praça, nem sempre se sabe. A tela usa o título.
  def titulo
    nome.presence || referencia.presence || "Academia nº #{id}"
  end

  # Rascunho: o autor edita. Publicada: só quem modera.
  def editavel_por?(user)
    return false unless user

    user.pode_moderar? || (autor_id == user.id && !visivel?)
  end

  # Para o formulário: { equipamento_id => quantidade }
  def quantidades
    academia_equipamentos.reject(&:marked_for_destruction?).to_h { |item| [ item.equipamento_id, item.quantidade ] }
  end

  # Recebe { "3" => "2", "5" => "0" }: quantidade zero remove o equipamento
  def quantidades=(valores)
    valores.to_h.each do |equipamento_id, quantidade|
      equipamento_id = equipamento_id.to_i
      quantidade = quantidade.to_i
      item = academia_equipamentos.find { |existente| existente.equipamento_id == equipamento_id }

      if quantidade.positive?
        item ? item.quantidade = quantidade : academia_equipamentos.build(equipamento_id:, quantidade:)
      elsif item
        item.mark_for_destruction
      end
    end
  end
end
