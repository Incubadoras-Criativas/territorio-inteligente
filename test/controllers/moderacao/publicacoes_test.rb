require "test_helper"

class Moderacao::PublicacoesTest < ActionDispatch::IntegrationTest
  test "moderadora vê e publica a academia em rascunho" do
    academia = academias(:rascunho_da_ana)
    sign_in users(:bia)

    get moderacao_path
    assert_select "##{ActionView::RecordIdentifier.dom_id(academia)}"

    patch publicar_moderacao_academia_path(academia), as: :turbo_stream

    assert_response :success
    assert academia.reload.visivel?
  end

  test "comum não publica" do
    academia = academias(:rascunho_da_ana)
    sign_in users(:ana)

    patch publicar_moderacao_academia_path(academia)

    assert_not academia.reload.visivel?
  end

  test "academia já publicada dá 404" do
    sign_in users(:bia)

    patch publicar_moderacao_academia_path(academias(:publicada))

    assert_response :not_found
  end

  test "o contador aparece só para quem modera" do
    sign_in users(:bia)
    get root_path
    assert_select ".contador"
    assert_select ".ponto-aviso"

    sign_out :user
    sign_in users(:ana)
    get root_path
    assert_select ".contador", count: 0
    assert_select ".ponto-aviso", count: 0
  end
end
