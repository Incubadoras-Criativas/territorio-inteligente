require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "usuário novo nasce comum" do
    assert User.new.comum?
  end

  test "gera o login a partir do primeiro nome" do
    user = User.create!(email: "maria@exemplo.com", password: "senha-segura-123", nome: "Maria da Silva")
    assert_equal "maria", user.login
  end

  test "numera o login quando o primeiro nome já existe" do
    user = User.create!(email: "ana2@exemplo.com", password: "senha-segura-123", nome: "Ana Souza")
    assert_equal "ana-1", user.login
  end

  def auth_google(email:, verificado: true, nome: "Bia Santos", uid: "123")
    OmniAuth::AuthHash.new(provider: "google_oauth2", uid: uid,
                           info: { email: email, name: nome, email_verified: verificado })
  end

  test "cria conta nova com o Google, já confirmada" do
    user = User.from_omniauth(auth_google(email: "bia@gmail.com"))
    assert user.persisted?
    assert user.confirmed?
    assert_equal "bia", user.login
    assert user.comum?
  end

  test "junta o Google a uma conta existente quando o e-mail é verificado" do
    user = User.from_omniauth(auth_google(email: "ana@exemplo.com", nome: "Ana"))
    assert_equal users(:ana), user
    assert_equal "google_oauth2", user.provider
  end

  test "não junta contas quando o Google não garante o e-mail" do
    user = User.from_omniauth(auth_google(email: "ana@exemplo.com", verificado: false))
    assert_not user.persisted?
  end

  test "avatar que saiu da galeria não é exibido" do
    user = users(:ana)
    user.avatar = "avatar-que-nao-existe.png"
    assert_nil user.avatar_exibivel
  end
end
