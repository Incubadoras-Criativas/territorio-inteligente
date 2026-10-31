class Equipamento < ApplicationRecord
  normalizes :slug, with: ->(slug) { slug.strip.downcase }

  before_validation :gerar_slug

  validates :nome, presence: true
  validates :slug, presence: true,
                   uniqueness: true,
                   format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ }

  # Nas URLs, o equipamento aparece pelo slug: /equipamentos/barra-fixa
  def to_param
    slug
  end

  # O guia é um arquivo HTML escrito por um aluno, lido do disco a cada pedido
  def conteudo
    arquivo.read if arquivo.exist?
  end

  # Foto principal: public/equipamentos/<slug>.jpg (ou .png / .webp)
  def imagem
    %w[jpg png webp].each do |ext|
      return "/equipamentos/#{slug}.#{ext}" if Rails.public_path.join("equipamentos", "#{slug}.#{ext}").exist?
    end
    nil
  end

  private

  def arquivo
    Rails.configuration.x.pasta_equipamentos.join("#{slug}.html")
  end

  def gerar_slug
    self.slug = nome.to_s.parameterize if slug.blank?
  end
end
