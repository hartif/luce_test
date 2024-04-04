# == Schema Information
#
# Table name: clients
#
#  id         :integer          not null, primary key
#  name       :string
#  phone      :string
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Client < ApplicationRecord
  has_many :invoices, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true

  # //input client data to contact xero
  def set_contact_xero
    token = Token.find_by_name "Xero"
    access_token = Token.req_xero_access_token token
    host = "https://api.xero.com/api.xro/2.0/Contacts"
    if self.xero_id.present?
      path = "?IDs=" + self.xero_id
      uri = URI(host+path)
      request = Net::HTTP::Get.new(uri)
      method = "GET"
    else
      uri = URI(host)
      request = Net::HTTP::Post.new(uri)
      request.body = JSON.dump({
        "Name": self.name
      })
      method = "POST"
    end
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request["Authorization"] = "Bearer " + access_token
    request["Accept"] = "application/json"
    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      if method != "GET"    
        self.update_column("xero_id", JSON.parse(response.body)["Contacts"].first["ContactID"] )
      end
      self.xero_id
    end
  end

  private

end
