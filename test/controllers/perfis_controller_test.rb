require "test_helper"

class PerfisControllerTest < ActionDispatch::IntegrationTest
  test "quem não está logado é mandado para o login" do
    get edit_perfil_url
    assert_redirected_to new_user_session_url
  end

  test "o usuário atualiza o próprio nome e login" do
    sign_in users(:ana)
    patch perfil_url, params: { user: { nome: "Ana Paula", login: "ana-paula" } }
    assert_redirected_to edit_perfil_url
    assert_equal "ana-paula", users(:ana).reload.login
  end

  test "ninguém muda o próprio nível de acesso pelo perfil" do
    sign_in users(:ana)
    patch perfil_url, params: { user: { nome: "Ana", role: "admin" } }
    assert users(:ana).reload.comum?
  end

  test "não dá para editar outro usuário enviando um id" do
    sign_in users(:ana)
    patch perfil_url, params: { id: users(:admin).id, user: { nome: "Hackeado" } }
    assert_equal "Admin", users(:admin).reload.nome
  end
end
