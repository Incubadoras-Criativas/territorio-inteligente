# Aplica ao registro as fotos escolhidas da galeria e as removidas no formulário.
# As imagens vêm só da galeria de quem está editando: um id de outra pessoa é ignorado.
module EscolheFotosDaGaleria
  extend ActiveSupport::Concern

  private

  def aplicar_fotos(registro)
    escolhas = params.fetch(registro.model_name.param_key, {})
    .permit(:capa_foto_id, imagem_ids: [], remover_foto_ids: [])

    registro.anexar_imagens(current_user.imagens.where(id: escolhas[:imagem_ids]), por: current_user)
    registro.remover_fotos(Array(escolhas[:remover_foto_ids]).map(&:to_i), por: current_user)
    registro.definir_capa(escolhas[:capa_foto_id])
  end
end
