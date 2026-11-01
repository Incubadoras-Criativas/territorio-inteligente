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

  test "o slug não muda quando já existe guia" do
    equipamento = equipamentos(:barra_fixa)
    assert_not equipamento.update(slug: "outro-nome")
    assert_includes equipamento.errors[:slug].first, "já tem guia"
  end

  test "o slug muda quando ainda não existe guia" do
    equipamento = equipamentos(:remada)
    assert equipamento.update(slug: "remada-sentada")
  end

  test "visiveis deixa os rascunhos de fora" do
    assert_not_includes Equipamento.visiveis, equipamentos(:rascunho)
  end

  test "aceita uma capa JPG" do
    equipamento = equipamentos(:remada)
    equipamento.capa.attach(io: file_fixture("foto.jpg").open, filename: "foto.jpg", content_type: "image/jpeg")
    assert equipamento.valid?
  end

  test "recusa um arquivo que não é imagem" do
    equipamento = equipamentos(:remada)
    equipamento.capa.attach(io: file_fixture("nao-e-imagem.txt").open, filename: "nao-e-imagem.txt", content_type: "text/plain")
    assert_not equipamento.valid?
    assert_includes equipamento.errors[:capa].first, "JPG, PNG ou WebP"
  end
end
