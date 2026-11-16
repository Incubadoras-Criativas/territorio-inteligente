class CreateImagens < ActiveRecord::Migration[8.1]
  def change
    create_table :imagens do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :termo_aceito_em

      t.timestamps
    end
  end
end
