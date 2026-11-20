class Observacao < ApplicationRecord
  include Moderavel
  include Fotografavel

  ESCALA = { boa: 0, regular: 1, ruim: 2, inutilizavel: 3, nao_se_aplica: 4 }.freeze
  ESCALA_DE_USO = { muito_usada: 0, pouco_usada: 1, sem_uso: 2 }.freeze
  CONDICOES = %i[conservacao acessibilidade limpeza iluminacao].freeze

  belongs_to :academia

  has_rich_text :relato


  # Vazio quer dizer "não observado"
  CONDICOES.each { |condicao| enum condicao, ESCALA, prefix: true, validate: { allow_nil: true } }
  enum :uso, ESCALA_DE_USO, prefix: true, validate: { allow_nil: true }

  attribute :data_da_visita, :date, default: -> { Date.current }

  scope :recentes, -> { order(data_da_visita: :desc, created_at: :desc) }

  validates :data_da_visita, presence: true,
                             comparison: { less_than_or_equal_to: ->(_observacao) { Date.current } }

  validate :nao_pode_ser_vazia

  def autor_publico
    autor if exibir_autor?
  end

  private

  def nao_pode_ser_vazia
    preenchida = CONDICOES.any? { |condicao| public_send(condicao).present? } ||
                 uso.present? || relato.to_plain_text.strip.present? || fotos.reject(&:marked_for_destruction?).any?
    errors.add(:base, "Preencha pelo menos uma condição, o relato ou uma foto.") unless preenchida
  end
end
