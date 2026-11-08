class RemoverTerritorios < ActiveRecord::Migration[8.1]
  def change
    remove_reference :academias, :territorio, foreign_key: true, index: true

    drop_table :territorios do |t|
      t.string :nome
      t.string :slug
      t.timestamps
      t.index :slug, unique: true
    end
  end
end
