class AddLimiteGaleriaMbToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :limite_galeria_mb, :integer, null: false, default: 100
  end
end
