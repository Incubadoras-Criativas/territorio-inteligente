class Categoria < ApplicationRecord
  include TemSlug

  has_many :academia_categorias, dependent: :destroy
  has_many :academias, through: :academia_categorias
end
