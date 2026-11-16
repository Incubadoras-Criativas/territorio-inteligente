require "test_helper"

class ImagemTest < ActiveSupport::TestCase
  setup do
    @user = users(:ana)
  end

  def arquivo
    { io: file_fixture("foto.jpg").open, filename: "foto.jpg", content_type: "image/jpeg" }
  end

  test "envia uma imagem para a galeria e grava a data do termo" do
    imagem = @user.imagens.create!(arquivo: arquivo, termo_fotos: true)

    assert_not_nil imagem.termo_aceito_em
    assert @user.espaco_usado.positive?
  end

  test "exige o aceite do termo" do
    imagem = @user.imagens.new(arquivo: arquivo)

    assert_not imagem.valid?
    assert imagem.errors.of_kind?(:termo_fotos, :accepted)
  end

  test "exige um arquivo" do
    imagem = @user.imagens.new(termo_fotos: true)

    assert_not imagem.valid?
    assert imagem.errors.of_kind?(:arquivo, :blank)
  end

  test "recusa a imagem quando a galeria está cheia" do
    @user.update!(limite_galeria_mb: 0)
    imagem = @user.imagens.new(arquivo: arquivo, termo_fotos: true)

    assert_not imagem.valid?
    assert_includes imagem.errors[:arquivo].join, "não cabe na sua galeria"
  end
end
