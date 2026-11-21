class ModeracaoMailer < ApplicationMailer
  # O resumo diário para quem modera. A contagem vem pronta do job, igual para todos.
  def resumo_diario(user, contagem)
    @user = user
    @contagem = contagem
    @total = contagem.values.sum

    mail to: user.email,
         subject: "Território Inteligente: #{@total} #{@total == 1 ? 'item aguarda' : 'itens aguardam'} moderação"
  end
end
