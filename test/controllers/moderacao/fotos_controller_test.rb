require "test_helper"

class Moderacao::FotosControllerTest < ActionDispatch::IntegrationTest
  setup do
    imagem = users(:ana).imagens.create!(
      arquivo: { io: file_fixture("foto.jpg").open, filename: "foto.jpg", content_type: "image/jpeg" },
      termo_fotos: true
    )
    @foto = Foto.create!(imagem: imagem, fotografavel: academias(:publicada), autor: users(:ana))
  end

  test "comum não entra na moderação" do
    sign_in users(:ana)

    get moderacao_path

    assert_redirected_to root_path
  end

  test "moderadora vê a foto pendente" do
    sign_in users(:bia)

    get moderacao_path

    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(@foto)}"
  end

  test "moderadora aprova, e a foto some da lista" do
    sign_in users(:bia)

    patch aprovar_moderacao_foto_path(@foto), as: :turbo_stream

    assert_response :success
    assert @foto.reload.aprovada?
    assert_equal users(:bia), @foto.moderador
  end

  test "moderadora recusa" do
    sign_in users(:bia)

    patch recusar_moderacao_foto_path(@foto)

    assert_redirected_to moderacao_path
    assert @foto.reload.recusada?
  end

  test "comum não aprova" do
    sign_in users(:ana)

    patch aprovar_moderacao_foto_path(@foto)

    assert @foto.reload.pendente?
  end

  test "foto já moderada dá 404" do
    @foto.aprovar!(por: users(:admin))
    sign_in users(:bia)

    patch recusar_moderacao_foto_path(@foto)

    assert_response :not_found
  end
end
