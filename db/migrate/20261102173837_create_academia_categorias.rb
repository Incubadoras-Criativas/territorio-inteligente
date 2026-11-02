class CreateAcademiaCategorias < ActiveRecord::Migration[8.1]
  def change
    create_table :academia_categorias do |t|
      t.references :academia, null: false, foreign_key: true
      t.references :categoria, null: false, foreign_key: true

      t.timestamps

      t.index [ :academia_id, :categoria_id ], unique: true
    end
  end
end
