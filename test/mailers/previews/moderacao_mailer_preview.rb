class ModeracaoMailerPreview < ActionMailer::Preview
  def resumo_diario
    ModeracaoMailer.resumo_diario(User.que_moderam.first, { fotos: 3, academias: 1, observacoes: 2 })
  end
end
