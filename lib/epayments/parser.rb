require 'mechanize'

class Parser

  def self.transfer_funds(login, password, sms_gateway, options)
    api = self.new(login, password)
    api.transfer_funds(options, sms_gateway)
  end

  public

    def initialize(login, password)
      @login, @password = login, password
      @agent = Mechanize.new do |a|
        a.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_1) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.89 Safari/537.1"
      end
      @page = @agent.get("https://#{self.class::SERVICE_URL}/")
      sign_in
    end

    def check_owner(options)
      raise "Not implemented yet!"
    end

    def transfer_funds(output_sum, output_wallet_num, id, domain, created_at)
      raise "Not implemented yet!"
    end

    def funds_recieved?(input_request)
      raise "Not implemented yet!"
    end

    def check_balance(account, currency)
      raise "Not implemented yet!"
    end

end

