# Uma imagem da galeria pessoal. Só o dono vê.
# Daqui ela pode ser anexada a academias, observações e equipamentos (etapa 0290).
class Imagem < ApplicationRecord
  include ValidaImagens

  belongs_to :user

  has_one_attached :arquivo do |anexo|
    anexo.variant :miniatura, resize_to_limit: [ 160, 160 ], format: :webp
    anexo.variant :media, resize_to_limit: [ 800, 800 ], format: :webp
  end

  attribute :termo_fotos, :boolean

  scope :recentes, -> { order(created_at: :desc) }

  valida_imagens :arquivo
  validates :termo_fotos, acceptance: { allow_nil: false, message: "precisa ser aceito para enviar fotos" }, on: :create
  validate :arquivo_presente
  validate :cabe_na_galeria, on: :create

  before_create { self.termo_aceito_em = Time.current }

  private

  def arquivo_presente
    errors.add(:arquivo, :blank) unless arquivo.attached?
  end

  def cabe_na_galeria
    return unless arquivo.attached? && user

    return if user.espaco_usado + arquivo.blob.byte_size <= user.limite_galeria_bytes

    errors.add(:arquivo, "não cabe na sua galeria (limite de #{user.limite_galeria_mb} MB)")
  end
end
