class CreateEquipamentos < ActiveRecord::Migration[8.1]
  def change
    create_table :equipamentos do |t|
      t.string :nome, null: false
      t.string :slug, null: false
      t.text :descricao

      t.timestamps
    end
    add_index :equipamentos, :slug, unique: true
  end
end
