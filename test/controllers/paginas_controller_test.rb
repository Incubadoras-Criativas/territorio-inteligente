require "test_helper"

class PaginasControllerTest < ActionDispatch::IntegrationTest
  test "a página inicial abre para quem não está logado" do
    get root_url
    assert_response :success
  end

  test "visitante vê Entrar na barra e não vê Usuários no menu" do
    get root_url
    assert_select ".barra-abas", text: /Entrar/
        assert_select "#menu-completo a", text: "Usuários", count: 0
  end

  test "administrador vê Usuários no menu" do
    sign_in users(:admin)
    get root_url
    assert_select "#menu-completo a", text: "Usuários"
  end

  test "a aba da página atual fica marcada" do
    get root_url
    assert_select ".barra-abas a[aria-current=page]", text: /Início/
  end

  test "login errado mostra o alerta" do
    post user_session_url, params: { user: { email: "ninguem@exemplo.com", password: "errada" } }
    assert_select ".alert[role=alert]", text: /inválid/
  end
end
