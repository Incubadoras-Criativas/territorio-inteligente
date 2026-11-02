require "test_helper"

class AcademiaTest < ActiveSupport::TestCase
  test "o autor edita o próprio rascunho, mas não depois de publicada" do
    academia = academias(:rascunho_da_ana)
    assert academia.editavel_por?(users(:ana))

    academia.visivel = true
    assert_not academia.editavel_por?(users(:ana))
  end

  test "a moderadora edita qualquer academia" do
    assert academias(:publicada).editavel_por?(users(:bia))
  end

  test "quantidades cria, altera e remove equipamentos" do
    academia = academias(:publicada)

    academia.update!(quantidades: { equipamentos(:remada).id.to_s => "2" })
    assert_equal 2, academia.academia_equipamentos.sole.quantidade

    academia.update!(quantidades: { equipamentos(:remada).id.to_s => "0" })
    assert_empty academia.reload.academia_equipamentos
  end

  test "latitude fora do mundo é recusada" do
    academia = academias(:publicada)
    academia.latitude = 120
    assert_not academia.valid?
  end

  test "sem nome, o título usa a referência" do
    academia = academias(:publicada)
    academia.nome = ""
    academia.referencia = "QE 38, área central"
    assert_equal "QE 38, área central", academia.titulo
  end
end
