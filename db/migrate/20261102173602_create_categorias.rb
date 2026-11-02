class CreateCategorias < ActiveRecord::Migration[8.1]
  def change
    create_table :categorias do |t|
      t.string :nome
      t.string :slug

      t.timestamps
    end
    add_index :categorias, :slug, unique: true
  end
end
