require "test_helper"

class ImagensControllerTest < ActionDispatch::IntegrationTest
  def foto = fixture_file_upload("foto.jpg", "image/jpeg")

  test "visitante não acessa a galeria" do
    get imagens_path

    assert_redirected_to new_user_session_path
  end

  test "envia imagens para a própria galeria" do
    sign_in users(:ana)

    assert_difference -> { users(:ana).imagens.count }, 2 do
      post imagens_path, params: { imagem: { arquivos: [ foto, foto ], termo_fotos: "1" } }
    end
    assert_redirected_to imagens_path
  end

  test "não envia sem aceitar o termo" do
    sign_in users(:ana)

    assert_no_difference -> { Imagem.count } do
      post imagens_path, params: { imagem: { arquivos: [ foto ], termo_fotos: "0" } }
    end
  end

  test "não remove a imagem de outra pessoa" do
    imagem = users(:bia).imagens.create!(arquivo: foto, termo_fotos: true)
    sign_in users(:ana)

    assert_no_difference -> { Imagem.count } do
      delete imagem_path(imagem)
    end
    assert_response :not_found
  end

  test "não vê a imagem de outra pessoa" do
    imagem = users(:bia).imagens.create!(arquivo: foto, termo_fotos: true)
    sign_in users(:ana)

    get imagem_path(imagem)

    assert_response :not_found
  end
end
