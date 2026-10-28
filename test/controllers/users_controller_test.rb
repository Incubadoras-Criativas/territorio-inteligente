require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "usuário comum não entra na administração" do
    sign_in users(:ana)
    get admin_users_url
    assert_redirected_to root_url
  end

  test "administrador vê a lista de usuários" do
    sign_in users(:admin)
    get admin_users_url
    assert_response :success
  end

  test "administrador promove um usuário a moderador" do
    sign_in users(:admin)
    patch admin_user_url(users(:ana)), params: { user: { role: "moderador" } }
    assert users(:ana).reload.moderador?
  end

  test "administrador não remove o próprio acesso" do
    sign_in users(:admin)
    patch admin_user_url(users(:admin)), params: { user: { role: "comum" } }
    assert users(:admin).reload.admin?
  end

  test "usuário comum não se promove pela administração" do
    sign_in users(:ana)
    patch admin_user_url(users(:ana)), params: { user: { role: "admin" } }
    assert users(:ana).reload.comum?
  end
end
