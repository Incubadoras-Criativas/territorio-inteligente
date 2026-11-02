# Nome obrigatório e slug gerado a partir dele, único e no formato
# letras-numeros-e-hifens. Usado em Equipamento, Territorio e Categoria.
module TemSlug
  extend ActiveSupport::Concern

  FORMATO_SLUG = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  included do
    normalizes :slug, with: ->(slug) { slug.strip.downcase }
    before_validation :gerar_slug

    validates :nome, presence: true
    validates :slug, presence: { if: -> { nome.present? } },
                     uniqueness: true,
                     format: { with: FORMATO_SLUG, allow_blank: true }
  end

  # Usa o slug do banco: se uma edição falhar, o formulário continua no endereço certo
  def to_param = slug_in_database || slug

  private

  def gerar_slug
    self.slug = nome.to_s.parameterize if slug.blank?
  end
end
