class Territorio < ApplicationRecord
  include TemSlug

  has_many :academias, dependent: :restrict_with_error
end
