require "test_helper"

class ModeracaoMailerTest < ActionMailer::TestCase
  test "resumo diário" do
    email = ModeracaoMailer.resumo_diario(users(:bia), { fotos: 2, academias: 1, observacoes: 0 })

    assert_equal [ users(:bia).email ], email.to
    assert_match "3 itens aguardam", email.subject
    assert_match "2 fotos", email.text_part.body.to_s
    assert_no_match "observaç", email.text_part.body.to_s
    assert_match "/moderacao", email.html_part.body.to_s
  end
end
