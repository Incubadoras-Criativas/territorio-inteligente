require "test_helper"

class AcademiasControllerTest < ActionDispatch::IntegrationTest
  def dados_validos(extra = {})
    { academia: {
                 nome: "Academia nova", territorio_id: territorios(:ceilandia).id,
                 latitude: "-15.81", longitude: "-48.10",
                 categoria_ids: [ categorias(:ao_ar_livre).id ]
                }.merge(extra) }
  end

  test "visitante vê a publicada e não vê o rascunho" do
    get academias_url
    assert_match "PEC da QNM 15", response.body
    assert_no_match "Praça do Cidadão", response.body

    get academia_url(academias(:rascunho_da_ana))
    assert_response :not_found
  end

  test "visitante não cadastra" do
    get new_academia_url
    assert_redirected_to new_user_session_path
  end

  test "comum cadastra, e a academia nasce como rascunho dele, mesmo tentando publicar" do
    sign_in users(:ana)

    assert_difference "Academia.count", 1 do
      post academias_url, params: dados_validos(visivel: "1")
    end

    academia = Academia.order(:created_at).last
    assert_not academia.visivel?
    assert_equal users(:ana), academia.autor
  end

  test "comum não edita a academia publicada" do
    sign_in users(:ana)
    get edit_academia_url(academias(:publicada))
    assert_redirected_to academia_path(academias(:publicada))
  end

  test "moderadora publica" do
    sign_in users(:bia)
    patch academia_url(academias(:rascunho_da_ana)), params: { academia: { visivel: "1" } }
    assert academias(:rascunho_da_ana).reload.visivel?
  end

  test "sem território, o erro aparece embaixo do campo" do
    sign_in users(:ana)
    post academias_url, params: dados_validos(territorio_id: "")
    assert_response :unprocessable_content
    assert_select "#academia_territorio_id_erro"
  end
end
