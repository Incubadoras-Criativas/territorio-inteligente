# Todo dia de manhã: se houver algo esperando decisão, avisa quem modera
class ResumoModeracaoJob < ApplicationJob
  queue_as :default

  def perform
    contagem = Moderacao::Pendencias.por_tipo
    return if contagem.values.sum.zero?

    User.que_moderam.find_each do |user|
      ModeracaoMailer.resumo_diario(user, contagem).deliver_later
    end
  end
end
