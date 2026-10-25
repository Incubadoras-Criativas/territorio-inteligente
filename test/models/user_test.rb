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
end
