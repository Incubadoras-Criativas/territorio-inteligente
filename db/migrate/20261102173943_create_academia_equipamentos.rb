class CreateAcademiaEquipamentos < ActiveRecord::Migration[8.1]
  def change
    create_table :academia_equipamentos do |t|
      t.references :academia, null: false, foreign_key: true
      t.references :equipamento, null: false, foreign_key: true
      t.integer :quantidade, default: 1, null: false

      t.timestamps

      t.index [ :academia_id, :equipamento_id ], unique: true
    end
  end
end
