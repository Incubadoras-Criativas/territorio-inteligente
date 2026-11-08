# Conteúdo enviado por usuários que passa por moderação antes de ser publicado.
# Rascunho: o autor vê e edita. Publicado: todos veem, só quem modera edita.
module Moderavel
  extend ActiveSupport::Concern

  included do
    belongs_to :autor, class_name: "User", optional: true
    scope :visiveis, -> { where(visivel: true) }
  end

  class_methods do
    # Visitante: só os publicados. Comum: os publicados e os próprios rascunhos. Moderador e admin: todos.
    def permitidas_para(user)
      return visiveis unless user
      return all if user.pode_moderar?

      visiveis.or(where(autor: user))
    end
  end

  def editavel_por?(user)
    return false unless user

    user.pode_moderar? || (autor_id == user.id && !visivel?)
  end
end
