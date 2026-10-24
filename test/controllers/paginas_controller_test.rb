require "test_helper"

class PaginasControllerTest < ActionDispatch::IntegrationTest
  test "a página inicial abre para quem não está logado" do
    get root_url
    assert_response :success
  end
end
