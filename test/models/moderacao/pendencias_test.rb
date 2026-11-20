require "test_helper"

class Moderacao::PendenciasTest < ActiveSupport::TestCase
  test "soma fotos pendentes e registros em rascunho" do
    imagem = users(:ana).imagens.create!(
      arquivo: { io: file_fixture("foto.jpg").open, filename: "foto.jpg", content_type: "image/jpeg" },
      termo_fotos: true
    )

    assert_difference -> { Moderacao::Pendencias.total }, 1 do
      Foto.create!(imagem: imagem, fotografavel: academias(:publicada), autor: users(:ana))
    end

    assert_difference -> { Moderacao::Pendencias.total }, -1 do
      academias(:rascunho_da_ana).publicar
    end
  end
end
