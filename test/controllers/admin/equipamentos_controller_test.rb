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

  test "admin escolhe fotos da galeria e define a capa" do
    sign_in users(:admin)
    imagens = 2.times.map do
      users(:admin).imagens.create!(
        arquivo: { io: file_fixture("foto.jpg").open, filename: "foto.jpg", content_type: "image/jpeg" },
        termo_fotos: true
      )
    end
    equipamento = equipamentos(:remada)

    patch admin_equipamento_path(equipamento),
          params: { equipamento: { nome: equipamento.nome, imagem_ids: imagens.map(&:id) } }
    assert_redirected_to admin_equipamentos_path
    assert equipamento.fotos.all?(&:aprovada?)

    segunda = equipamento.fotos.find_by!(imagem: imagens.last)
    patch admin_equipamento_path(equipamento),
          params: { equipamento: { nome: equipamento.nome, capa_foto_id: segunda.id } }

    assert_equal segunda, equipamento.reload.foto_de_capa
  end
end
