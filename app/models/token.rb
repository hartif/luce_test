class Token < ApplicationRecord

	def is_active
    DateTime.now < self.expired_at
  end

  # //request access token xero
	def self.req_xero_access_token token=nil
		if token.present? && token.is_active
			return token.access_token
		else
	    client_id = "56A71901034D43F6A150BB838500BDAB" #ENV["XERO_KEY"]
	    secret    = "hqn877qEH2PVe--y03d5wi9HSUkFC47DoE9kGsSuF-_Wltgv" #ENV["XERO_SECRET"]
	    auth = Base64.strict_encode64(client_id+":"+secret)
	    uri  = URI("https://identity.xero.com/connect/token")
	    http = Net::HTTP.new(uri.host, uri.port)
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	    request = Net::HTTP::Post.new(uri)
	    request["Authorization"] = "Basic " + auth
	    request["content-type"] = "application/x-www-form-urlencoded"
	    params =  {
	         :grant_type => "client_credentials",
	         :scopes => 'accounting.transactions accounting.transactions.read accounting.contacts accounting.contacts.read'       
	       }
	    request.set_form_data(params)
	    response = http.request(request)
	    if response.is_a?(Net::HTTPSuccess)
	      unless token.present?
	        token = Token.new(name: "Xero", token_type: "Bearer" )
	      end     
	      token.access_token = JSON.parse(response.body)["access_token"]
	      token.expired_at = Time.now + 30.minutes
	      if token.save
	        return JSON.parse(response.body)["access_token"]
	      else
	        return nil
	      end
	    else
	      return nil
	    end
	  end
  end

end
