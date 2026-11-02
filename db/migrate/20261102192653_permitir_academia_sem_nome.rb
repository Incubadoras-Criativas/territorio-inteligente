class PermitirAcademiaSemNome < ActiveRecord::Migration[8.1]
  def change
    change_column_null :academias, :nome, true
  end
end
