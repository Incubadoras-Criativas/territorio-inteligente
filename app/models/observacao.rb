class Observacao < ApplicationRecord
  include Moderavel
  include ValidaImagens

  ESCALA = { boa: 0, regular: 1, ruim: 2, inutilizavel: 3, nao_se_aplica: 4 }.freeze
  ESCALA_DE_USO = { muito_usada: 0, pouco_usada: 1, sem_uso: 2 }.freeze
  CONDICOES = %i[conservacao acessibilidade limpeza iluminacao].freeze

  belongs_to :academia

  has_rich_text :relato

  has_many_attached :fotos do |anexo|
    anexo.variant :miniatura, resize_to_limit: [ 160, 160 ], format: :webp
    anexo.variant :media, resize_to_limit: [ 800, 800 ], format: :webp
  end

  # Vazio quer dizer "não observado"
  CONDICOES.each { |condicao| enum condicao, ESCALA, prefix: true, validate: { allow_nil: true } }
  enum :uso, ESCALA_DE_USO, prefix: true, validate: { allow_nil: true }

  attribute :data_da_visita, :date, default: -> { Date.current }
  attribute :termo_fotos, :boolean

  scope :recentes, -> { order(data_da_visita: :desc, created_at: :desc) }

  valida_imagens :fotos
  validates :data_da_visita, presence: true,
                             comparison: { less_than_or_equal_to: ->(_observacao) { Date.current } }
  validates :termo_fotos, acceptance: { allow_nil: false, message: "precisa ser aceito para enviar fotos" }, if: :fotos_novas?

  validate :nao_pode_ser_vazia

  before_save :registrar_termo, if: :fotos_novas?

  def autor_publico
    autor if exibir_autor?
  end

  private

  # Foto nova = arquivo enviado agora. As fotos mantidas no formulário
  # (pelo "Manter esta foto") já existem, e não pedem o termo de novo.
  def fotos_novas?
    mudanca = attachment_changes["fotos"]
    mudanca.respond_to?(:blobs) && mudanca.blobs.any?(&:new_record?)
  end

  def registrar_termo
    self.termo_fotos_aceito_em = Time.current
  end

  def nao_pode_ser_vazia
    preenchida = CONDICOES.any? { |condicao| public_send(condicao).present? } ||
                 uso.present? || relato.to_plain_text.strip.present? || fotos.attached?
    errors.add(:base, "Preencha pelo menos uma condição, o relato ou uma foto.") unless preenchida
  end
end
