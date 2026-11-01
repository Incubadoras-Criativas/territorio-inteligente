class AddVisivelToEquipamentos < ActiveRecord::Migration[8.1]
  def change
    add_column :equipamentos, :visivel, :boolean, default: false, null: false
  end
end
