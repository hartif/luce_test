class CreateTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :tokens do |t|
      t.string :name
      t.text :access_token
      t.datetime :expired_at
      t.string :token_type
      t.timestamps
    end
  end
end
