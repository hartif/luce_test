class AddXeroIndetifierToInvoices < ActiveRecord::Migration[7.0]
  def change
    add_column :invoices, :xero_invoice_number, :string
    add_column :transactions, :xero_id, :string
  end
end
