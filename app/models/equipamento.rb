class Equipamento < ApplicationRecord
  normalizes :slug, with: ->(slug) { slug.strip.downcase }

  before_validation :gerar_slug

  validates :nome, presence: true
  validates :slug, presence: { if: -> { nome.present? } },
                   uniqueness: true,
                   format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/, allow_blank: true }
  validate :slug_travado_com_guia, on: :update

  scope :visiveis, -> { where(visivel: true) }

  # Nas URLs, o equipamento aparece pelo slug: /equipamentos/barra-fixa
  # Usa o slug do banco: se uma edição falhar, o formulário continua no endereço certo
  def to_param = slug_in_database || slug

  def tem_guia? = arquivo.exist?

  # O guia é um arquivo HTML escrito por um aluno, lido do disco a cada pedido
  def conteudo
    arquivo.read if tem_guia?
  end

  # Foto principal: public/equipamentos/<slug>.jpg (ou .png / .webp)
  def imagem
    %w[jpg png webp].each do |ext|
      return "/equipamentos/#{slug}.#{ext}" if Rails.public_path.join("equipamentos", "#{slug}.#{ext}").exist?
    end
    nil
  end

  private

  def arquivo(s = slug) = Rails.configuration.x.pasta_equipamentos.join("#{s}.html")

  def gerar_slug
    self.slug = nome.to_s.parameterize if slug.blank?
  end

  def slug_travado_com_guia
    return unless will_save_change_to_slug? && arquivo(slug_in_database).exist?

    errors.add(:slug, "não pode mudar: este equipamento já tem guia. Renomeie o arquivo por Pull Request.")
  end
end
