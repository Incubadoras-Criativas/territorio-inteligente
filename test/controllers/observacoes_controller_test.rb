require "test_helper"

class ObservacoesControllerTest < ActionDispatch::IntegrationTest
  test "depois de cadastrar a academia, vai para a primeira observação" do
    sign_in users(:ana)
    post academias_url, params: { academia: {
                                             latitude: "-15.81", longitude: "-48.10", categoria_ids: [ categorias(:ao_ar_livre).id ]
                                            } }
    assert_redirected_to new_academia_observacao_path(Academia.order(:created_at).last)
  end

  test "comum registra, e a observação nasce como rascunho, mesmo tentando publicar" do
    sign_in users(:ana)

    assert_difference "Observacao.count", 1 do
      post academia_observacoes_url(academias(:publicada)),
           params: { observacao: { conservacao: "boa", visivel: "1" } }
    end
    assert_not Observacao.order(:created_at).last.visivel?
  end

  test "a ficha não mostra o rascunho alheio a visitantes" do
    get academia_url(academias(:publicada))
    assert_select ".observacao", count: 1
  end

  test "a moderadora publica" do
    sign_in users(:bia)
    patch academia_observacao_url(academias(:publicada), observacoes(:rascunho_da_ana)),
          params: { observacao: { visivel: "1" } }
    assert observacoes(:rascunho_da_ana).reload.visivel?
  end
end
