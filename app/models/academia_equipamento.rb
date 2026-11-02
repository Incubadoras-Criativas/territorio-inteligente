class AcademiaEquipamento < ApplicationRecord
  belongs_to :academia
  belongs_to :equipamento

  validates :quantidade, numericality: { only_integer: true, greater_than: 0 }
end
