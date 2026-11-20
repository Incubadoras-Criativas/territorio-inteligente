class Equipamento < ApplicationRecord
  include TemSlug
  include Fotografavel

  has_many :academia_equipamentos, dependent: :restrict_with_error

  validate :slug_travado_com_guia, on: :update

  scope :visiveis, -> { where(visivel: true) }

  def tem_guia? = arquivo.exist?

  # O guia é um arquivo HTML escrito por um aluno, lido do disco a cada pedido
  def conteudo
    arquivo.read if tem_guia?
  end

  private

  def arquivo(s = slug) = Rails.configuration.x.pasta_equipamentos.join("#{s}.html")

  def slug_travado_com_guia
    return unless will_save_change_to_slug? && arquivo(slug_in_database).exist?

    errors.add(:slug, "não pode mudar: este equipamento já tem guia. Renomeie o arquivo por Pull Request.")
  end
end
