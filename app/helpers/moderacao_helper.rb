module ModeracaoHelper
  # O nome do registro onde a foto foi anexada
  def descricao_do_registro(registro)
    case registro
    when Academia then registro.titulo
    when Observacao then "Observação de #{l registro.data_da_visita} em #{registro.academia.titulo}"
    when Equipamento then registro.nome
    end
  end

  # O endereço do registro. A observação não tem página própria: vai para a ficha da academia
  def caminho_do_registro(registro)
    case registro
    when Observacao then academia_path(registro.academia, anchor: dom_id(registro))
    else polymorphic_path(registro)
    end
  end
end
