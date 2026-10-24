class AddNomeAndLoginToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :nome, :string
    add_column :users, :login, :string

    # Usuários que já existem ganham valores provisórios
    execute <<~SQL
      UPDATE users
        SET nome  = split_part(email, '@', 1),
           login = 'usuario-' || id
    SQL

    change_column_null :users, :nome, false
    change_column_null :users, :login, false
    add_index :users, "lower(login)", unique: true
  end

  def down
    remove_column :users, :login
    remove_column :users, :nome
  end
end
