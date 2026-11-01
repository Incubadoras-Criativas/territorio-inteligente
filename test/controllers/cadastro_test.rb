require "test_helper"

class CadastroTest < ActionDispatch::IntegrationTest
  test "senhas diferentes mostram o erro embaixo da confirmação" do
    post user_registration_url, params: { user: {
                                                 nome: "Teste", email: "novo@exemplo.com",
                                                 password: "senha-segura-123", password_confirmation: "outra-senha"
                                                } }

    assert_response :unprocessable_content
    assert_select "input#user_password_confirmation[aria-invalid=true]"
    assert_select "#user_password_confirmation_erro"
  end

  test "e-mail repetido mostra o erro embaixo do e-mail" do
    post user_registration_url, params: { user: {
                                                 nome: "Teste", email: users(:ana).email,
                                                 password: "senha-segura-123", password_confirmation: "senha-segura-123"
                                                } }

    assert_select "#user_email_erro", text: /já está em uso/
  end
end
