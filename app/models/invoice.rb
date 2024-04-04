# == Schema Information
#
# Table name: invoices
#
#  id             :integer          not null, primary key
#  status         :string
#  payment_status :string
#  amount         :float
#  paid_amount    :float
#  issue_date     :date
#  due_date       :date
#  client_id      :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Invoice < ApplicationRecord
  STATUSES = %w[NEW CONFIRMED CANCELLED].freeze
  PAYMENT_STATUSES = %w[PAID UNPAID UNDERPAID].freeze

  belongs_to :client
  has_many :transactions, dependent: :destroy

  validates :status, presence: true, inclusion: STATUSES
  validates :payment_status, presence: true, inclusion: PAYMENT_STATUSES

  scope :by_client_id, ->(client_id) { where(client_id: client_id) }

  def cancel
    update(status: 'CANCELLED')
  end

  def confirm
    update(status: 'CONFIRMED')
  end

  def update_amount
    update(amount: compute_amount)
  end

  def compute_amount
    if transactions.empty?
      0
    else
      transactions.sum(&:amount)
    end
  end

  # //invoice simple code to identifier
  def self.random_simple_alphanumeric size=8
    arr = [(0..9), ('a'..'z')].map(&:to_a).flatten
    (0...size).map{ arr[rand(arr.length)] }.join
  end  

  # //input invoice data to xero
  def set_invoice_request status
    token = Token.find_by_name "Xero"
    contact = self.client
    access_token = Token.req_xero_access_token token
    unless contact.xero_id.present?
      contact_id = contact.set_contact_xero
    else
      contact_id = contact.xero_id
    end
    uri  = URI("https://api.xero.com/api.xro/2.0/Invoices")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri)
    transactions = self.transactions
    array = []
    transactions_json = transactions.each_with_object([]) {|c, array| array << c.set_obj }
    request.body = JSON.dump({
      "Type": "ACCREC",
      "DueDate": self.due_date,
      "InvoiceNumber": self.xero_invoice_number,
      "Status": status,
      "CurrencyCode": "SGD",
      "Contact" => {
        "ContactID" => contact_id
      },
      "LineItems" => transactions_json
    })
    request["Authorization"] = "Bearer " + access_token
    request["Accept"] = "application/json"
    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      res_body = JSON.parse(response.body)
      transactions.each_with_index do |transaction, index|
        transaction.update_column("xero_id", res_body["Invoices"].first["LineItems"][index]["LineItemID"]) if transaction.xero_id.blank?
      end
    end
  end

end
