class CreateObservacoes < ActiveRecord::Migration[8.1]
  def change
    create_table :observacoes do |t|
      t.references :academia, null: false, foreign_key: true
      t.references :autor, foreign_key: { to_table: :users, on_delete: :nullify }
      t.date :data_da_visita, null: false
      t.integer :conservacao
      t.integer :acessibilidade
      t.integer :limpeza
      t.integer :iluminacao
      t.integer :uso
      t.boolean :visivel, default: false, null: false
      t.boolean :exibir_autor, default: false, null: false
      t.datetime :termo_fotos_aceito_em

      t.timestamps
    end
  end
end
