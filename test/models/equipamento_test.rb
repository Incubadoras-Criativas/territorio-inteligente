require "test_helper"

class EquipamentoTest < ActiveSupport::TestCase
  test "gera o slug a partir do nome" do
    equipamento = Equipamento.create!(nome: "Simulador de Caminhada")
    assert_equal "simulador-de-caminhada", equipamento.slug
  end

  test "recusa slug que tenta sair da pasta" do
    equipamento = Equipamento.new(nome: "Ataque", slug: "../../config/master")
    assert_not equipamento.valid?
  end

  test "lê o conteúdo do arquivo do equipamento" do
    assert_match "Conteúdo de teste", equipamentos(:barra_fixa).conteudo
  end

  test "sem arquivo, não há conteúdo" do
    assert_nil equipamentos(:remada).conteudo
  end
end
