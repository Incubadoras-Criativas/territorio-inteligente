class CreateTerritorios < ActiveRecord::Migration[8.1]
  def change
    create_table :territorios do |t|
      t.string :nome
      t.string :slug

      t.timestamps
    end
    add_index :territorios, :slug, unique: true
  end
end
