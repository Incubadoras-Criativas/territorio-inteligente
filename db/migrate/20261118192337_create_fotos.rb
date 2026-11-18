class CreateFotos < ActiveRecord::Migration[8.1]
  def change
    create_table :fotos do |t|
      t.references :imagem, null: false, foreign_key: true
      t.references :fotografavel, polymorphic: true, null: false
      t.references :autor, null: false, foreign_key: { to_table: :users }
      t.references :moderador, foreign_key: { to_table: :users }
      t.integer :situacao, null: false, default: 0
      t.boolean :capa, null: false, default: false
      t.datetime :moderado_em

      t.timestamps
    end

    add_index :fotos, %i[fotografavel_type fotografavel_id imagem_id],
              unique: true, name: "index_fotos_uma_vez_por_registro"
  end
end
