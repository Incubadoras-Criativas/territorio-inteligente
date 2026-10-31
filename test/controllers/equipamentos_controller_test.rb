require "test_helper"

class EquipamentosControllerTest < ActionDispatch::IntegrationTest
  test "a lista é pública" do
    get equipamentos_url
    assert_response :success
  end

  test "o guia mostra o conteúdo do arquivo" do
    get equipamento_url(equipamentos(:barra_fixa))
    assert_match "Conteúdo de teste", response.body
  end

  test "sem arquivo, o guia avisa que está em construção" do
    get equipamento_url(equipamentos(:remada))
    assert_match "em construção", response.body
  end

  test "slug inexistente dá 404" do
    get "/equipamentos/nao-existe"
    assert_response :not_found
  end
end
