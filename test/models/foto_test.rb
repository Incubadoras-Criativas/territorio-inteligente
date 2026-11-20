require "test_helper"

class FotoTest < ActiveSupport::TestCase
  setup do
    @academia = academias(:publicada)
    @ana = users(:ana)
    @imagem = @ana.imagens.create!(arquivo: arquivo, termo_fotos: true)
  end

  def arquivo
    { io: file_fixture("foto.jpg").open, filename: "foto.jpg", content_type: "image/jpeg" }
  end

  test "nasce pendente" do
    foto = Foto.create!(imagem: @imagem, fotografavel: @academia, autor: @ana)

    assert foto.pendente?
  end

  test "não anexa a imagem da galeria de outra pessoa" do
    foto = Foto.new(imagem: @imagem, fotografavel: @academia, autor: users(:bia))

    assert_not foto.valid?
    assert foto.errors.of_kind?(:imagem, "precisa ser da sua galeria")
  end

  test "não anexa a mesma imagem duas vezes ao mesmo registro" do
    Foto.create!(imagem: @imagem, fotografavel: @academia, autor: @ana)
    repetida = Foto.new(imagem: @imagem, fotografavel: @academia, autor: @ana)

    assert_not repetida.valid?
  end

  test "o autor remove enquanto não aprovada; quem modera remove sempre" do
    foto = Foto.create!(imagem: @imagem, fotografavel: @academia, autor: @ana)
    assert foto.removivel_por?(@ana)

    foto.recusar!(por: users(:bia))
    assert foto.removivel_por?(@ana)

    foto.aprovar!(por: users(:bia))
    assert_not foto.removivel_por?(@ana)
    assert foto.removivel_por?(users(:bia))
  end

  test "a moderação registra quem moderou e quando" do
    foto = Foto.create!(imagem: @imagem, fotografavel: @academia, autor: @ana)

    foto.aprovar!(por: users(:bia))

    assert foto.aprovada?
    assert_equal users(:bia), foto.moderador
    assert_not_nil foto.moderado_em
  end

  test "apagar a imagem remove a foto do registro" do
    Foto.create!(imagem: @imagem, fotografavel: @academia, autor: @ana)

    assert_difference -> { Foto.count }, -1 do
      @imagem.destroy
    end
  end
end
