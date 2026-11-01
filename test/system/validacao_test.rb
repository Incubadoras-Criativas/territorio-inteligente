require "application_system_test_case"

class ValidacaoTest < ApplicationSystemTestCase
  test "e-mail inválido mostra o erro ao sair do campo" do
    visit new_user_registration_path

    fill_in "E-mail", with: "luiz.mail.com"
    find_field("E-mail").send_keys(:tab)

    assert_selector "#user_email.com-erro[aria-invalid=true]"
    assert_selector "#user_email_erro", text: "Digite um e-mail válido"
  end

  test "o erro some quando a pessoa corrige" do
    visit new_user_registration_path

    fill_in "E-mail", with: "luiz.mail.com"
    find_field("E-mail").send_keys(:tab)
    fill_in "E-mail", with: "luiz@mail.com"

    assert_no_selector "#user_email_erro"
  end

  test "não envia com campo obrigatório vazio e leva o cursor até ele" do
    visit new_user_session_path
    click_on "Login"

    assert_selector "#user_email_erro", text: "Preencha este campo"
    assert_current_path new_user_session_path
  end
end
