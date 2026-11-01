class Equipamento < ApplicationRecord
  normalizes :slug, with: ->(slug) { slug.strip.downcase }

  before_validation :gerar_slug

  validates :nome, presence: true
  validates :slug, presence: { if: -> { nome.present? } },
                   uniqueness: true,
                   format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/, allow_blank: true }
  validate :slug_travado_com_guia, on: :update

  scope :visiveis, -> { where(visivel: true) }

  TIPOS_DE_IMAGEM = %w[image/jpeg image/png image/webp].freeze
  TAMANHO_MAXIMO = 10.megabytes

  # A foto do cartão e do topo da página
  has_one_attached :capa do |anexo|
    anexo.variant :miniatura, resize_to_limit: [ 160, 160 ], format: :webp
  end

  # A galeria, abaixo do guia
  has_many_attached :fotos do |anexo|
    anexo.variant :media, resize_to_limit: [ 800, 800 ], format: :webp
  end

  validate :imagens_validas

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

  def imagens_validas
    anexos = fotos.attachments.to_a
    anexos << capa.attachment if capa.attached?

    anexos.each do |anexo|
      unless anexo.blob.content_type.in?(TIPOS_DE_IMAGEM)
        errors.add(anexo.name.to_sym, "precisa ser uma imagem JPG, PNG ou WebP")
      end

      if anexo.blob.byte_size > TAMANHO_MAXIMO
        errors.add(anexo.name.to_sym, "precisa ter no máximo 10 MB")
      end
    end
  end
end
