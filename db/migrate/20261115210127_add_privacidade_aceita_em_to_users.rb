class AddPrivacidadeAceitaEmToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :privacidade_aceita_em, :datetime
  end
end
