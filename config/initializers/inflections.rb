# O Rails pluraliza em inglês: palavras terminadas em "ia" (media, criteria)
# ficariam iguais no plural. Ensinamos as nossas.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "academia", "academias"
  inflect.irregular "categoria", "categorias"
  inflect.irregular "observacao", "observacoes"
end
