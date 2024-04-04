class AddXeroIdToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :xero_id, :string
  end
end
