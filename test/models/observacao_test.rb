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

  test "o autor só aparece se ele quiser" do
    assert_nil observacoes(:publicada).autor_publico

    observacoes(:publicada).exibir_autor = true
    assert_equal users(:ana), observacoes(:publicada).autor_publico
  end
end
