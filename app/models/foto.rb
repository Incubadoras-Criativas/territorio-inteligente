# O vínculo entre uma imagem da galeria e um registro (academia, observação ou equipamento).
# Quem pode moderar anexa já aprovada; os demais anexam como pendente.
class Foto < ApplicationRecord
  belongs_to :imagem
  belongs_to :fotografavel, polymorphic: true
  belongs_to :autor, class_name: "User"
  belongs_to :moderador, class_name: "User", optional: true

  enum :situacao, { pendente: 0, aprovada: 1, recusada: 2 }

  scope :capas, -> { where(capa: true) }

  validates :imagem_id, uniqueness: { scope: %i[fotografavel_type fotografavel_id] }
  validate :imagem_da_galeria_do_autor

  def removivel_por?(user)
    return false unless user

    user.pode_moderar? || (autor_id == user.id && pendente?)
  end

  private

  def imagem_da_galeria_do_autor
    return unless imagem && imagem.user_id != autor_id

    errors.add(:imagem, "precisa ser da sua galeria")
  end
end
