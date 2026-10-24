require "test_helper"

class PaginasControllerTest < ActionDispatch::IntegrationTest
  test "should get inicio" do
    get paginas_inicio_url
    assert_response :success
  end
end
