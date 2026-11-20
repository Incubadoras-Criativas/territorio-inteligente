class RemoveTermoFotosAceitoEmFromObservacoes < ActiveRecord::Migration[8.1]
  def change
    remove_column :observacoes, :termo_fotos_aceito_em, :datetime
  end
end
