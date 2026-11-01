require "test_helper"

class Admin::EquipamentosControllerTest < ActionDispatch::IntegrationTest
  test "usuário comum não entra" do
    sign_in users(:ana)
    get admin_equipamentos_url
    assert_redirected_to root_path
  end

  test "admin cadastra equipamento, que nasce escondido" do
    sign_in users(:admin)

    assert_difference "Equipamento.count", 1 do
      post admin_equipamentos_url, params: { equipamento: { nome: "Surf" } }
    end

    equipamento = Equipamento.find_by!(slug: "surf")
    assert_not equipamento.visivel
    assert_redirected_to admin_equipamentos_path
  end

  test "admin publica um equipamento" do
    sign_in users(:admin)
    patch admin_equipamento_url(equipamentos(:rascunho)), params: { equipamento: { visivel: "1" } }
    assert equipamentos(:rascunho).reload.visivel
  end

  test "cadastro sem nome mostra o erro embaixo do campo" do
    sign_in users(:admin)
    post admin_equipamentos_url, params: { equipamento: { nome: "" } }
    assert_response :unprocessable_content
    assert_select ".erro-campo"

    assert_select "input#equipamento_nome.com-erro[aria-invalid=true][aria-describedby=equipamento_nome_erro]"
    assert_select "p#equipamento_nome_erro.erro-campo"
    assert_select ".aviso-erros[role=alert]"
    assert_select ".field_with_errors", count: 0
  end

  test "admin envia a capa e uma foto da galeria" do
    sign_in users(:admin)
    equipamento = equipamentos(:rascunho)

    patch admin_equipamento_url(equipamento), params: { equipamento: {
                                                                      capa: fixture_file_upload("foto.jpg", "image/jpeg"),
                                                                      fotos: [ fixture_file_upload("foto.jpg", "image/jpeg") ]
                                                                     } }

    equipamento.reload
    assert equipamento.capa.attached?
    assert_equal 1, equipamento.fotos.count
  end

  test "arquivo que não é imagem mostra o erro embaixo do campo" do
    sign_in users(:admin)

    patch admin_equipamento_url(equipamentos(:rascunho)), params: { equipamento: {
                                                                                  capa: fixture_file_upload("nao-e-imagem.txt", "text/plain")
                                                                                 } }

    assert_response :unprocessable_content
    assert_select "#equipamento_capa_erro", text: /JPG, PNG ou WebP/
        end
end
