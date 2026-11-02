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

  test "visitante não vê rascunho na lista nem na página" do
    get equipamentos_url
    assert_no_match "Rotação diagonal", response.body

    get equipamento_url(equipamentos(:rascunho))
    assert_response :not_found
  end

  test "admin vê a página do rascunho com aviso" do
    sign_in users(:admin)
    get equipamento_url(equipamentos(:rascunho))
    assert_response :success
    assert_select ".aviso-rascunho"
  end

  test "admin vê o rascunho na lista, com a etiqueta" do
    sign_in users(:admin)
    get equipamentos_url
    assert_select ".etiqueta-rascunho", count: 1
  end

  test "a página de um equipamento com capa abre" do
    equipamento = equipamentos(:barra_fixa)
    equipamento.capa.attach(io: file_fixture("foto.jpg").open, filename: "foto.jpg", content_type: "image/jpeg")

    get equipamento_url(equipamento)
    assert_response :success
    assert_select "img.capa"
  end
end
