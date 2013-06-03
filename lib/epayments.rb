require 'net/http'
require 'net/https'
require "epayments/exception"
require "epayments/parser"

class Epayments < Parser
  SERVICE_URL = "www.epayments.com"
  LOCATIONS = {
    :transfer_url => "/payment/internalpayment",
    :input_payments_url => "/transactions?type=wallet"
  }

  public

  def sign_in
    @page = @page.form_with :id => "loginForm" do |f|
      f.UserName = @login
      f.Password = @password
    end.submit
  end

  def transfer_funds(options, sms_gateway)
    @sms_gateway = sms_gateway
    navigate(:transfer_url)
    wallet_num_part1, wallet_num_part2 = split_wallet(options[:to])

    @page = @page.form_with :id => "Form" do |f|
      f.Amount = options[:amount]
      f.TargetWalletNumberPart1 = wallet_num_part1
      f.TargetWalletNumberPart2 = wallet_num_part2
      f.Details = "#{options[:id]} #{options[:domain]}"
    end.submit
    wait(20)

    code = get_transfer_validation_code(options[:created_at])
    @page = @page.form_with :id => "Form" do |f|
      f.PayCode = code
    end.submit

    if @page.search(".cab_content p")[0].text.strip == "Your Internal Payment has been processed"
      true
    else
      raise EpaymentsException, @page.search(".cab_content p")[0].text
    end
  end

  private

  def navigate(location)
    @page = @agent.get("https://#{SERVICE_URL}/#{LOCATIONS[location]}")
  end

  def save_current_page(name)
    @page.save("#{name}.html")
  end

  def split_wallet(wallet_num)
    wallet_num.split("-")
  end

  def get_transfer_validation_code(request_created_at)
    sms_list = @sms_gateway.get_sms_list
    code = nil
    sms_list.reverse.each do |sms|
      if (sms["phone"] == "EPA") && ((sms["sent"] + " +0400").to_datetime > request_created_at)
        code = sms["message"].split("n").last.strip 
      end
    end
    raise EpaymentsException, "Unknown sms code" if code.nil?
    code
  end

  def wait(seconds)
    sleep(seconds)  
  end

end
