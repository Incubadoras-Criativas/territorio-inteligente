class CreateAcademias < ActiveRecord::Migration[8.1]
  def change
    create_table :academias do |t|
      t.string :nome, null: false
      t.string :referencia
      t.references :territorio, null: false, foreign_key: true
      t.decimal :latitude, precision: 9, scale: 6, null: false
      t.decimal :longitude, precision: 9, scale: 6, null: false
      t.boolean :visivel, default: false, null: false
      t.references :autor, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps
    end
  end
end
