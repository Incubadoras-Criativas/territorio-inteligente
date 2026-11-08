require "test_helper"

class ObservacaoTest < ActiveSupport::TestCase
  test "observação vazia não salva" do
    observacao = academias(:publicada).observacoes.build
    assert_not observacao.valid?
    assert_includes observacao.errors[:base].first, "pelo menos uma condição"
  end

  test "data no futuro é recusada" do
    observacao = observacoes(:publicada)
    observacao.data_da_visita = Date.current + 1
    assert_not observacao.valid?
  end

  test "valor fora da escala vira erro, e não exceção" do
    observacao = observacoes(:publicada)
    observacao.conservacao = "otima"
    assert_not observacao.valid?
  end

  test "foto nova exige o termo, e o aceite fica registrado" do
    observacao = academias(:publicada).observacoes.build(conservacao: "boa", autor: users(:ana))
    observacao.fotos.attach(io: file_fixture("foto.jpg").open, filename: "foto.jpg", content_type: "image/jpeg")
    assert_not observacao.valid?

    observacao.termo_fotos = true
    observacao.save!
    assert observacao.termo_fotos_aceito_em.present?
  end

  test "o autor só aparece se ele quiser" do
    assert_nil observacoes(:publicada).autor_publico

    observacoes(:publicada).exibir_autor = true
    assert_equal users(:ana), observacoes(:publicada).autor_publico
  end
end
