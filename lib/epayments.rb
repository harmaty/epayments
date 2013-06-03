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

  def check_balance
    sum = @page.search(".card_money").first.children[3].children[0].children[0].text.to_f
  end

  def funds_recieved?(input_request)
    navigate(:input_payments_url)
    transactions = last_transactions_list
    transactions.each do |transaction|
      if (transaction[:date].to_time > input_request.created_at.to_datetime) && (transaction[:amount].to_f == input_request.input_sum.to_f) && (transaction[:wallet_num] == input_request.input_wallet_num)
        return transaction[:transaction_id]
      end
    end
    nil
  end

  def last_transactions_list
    transaction_list = []
    rows = @page.search("table").children
    rows.shift
    rows.each do |transaction|
      transaction_list << {
        :date => transaction.search(".date").text.strip.gsub("\r\n", "").gsub("/", "-") + ":59",
        :currency => transaction.search(".currency").text.strip.gsub("\r\n", ""),
        :amount => transaction.search(".credits").text.strip.gsub("\r\n", ""),
        :transaction_id => transaction.search(".payment").text.strip.gsub("\r\n", ""),
        :description => transaction.search(".description").text.strip.gsub("\r\n", ""),
        :wallet_num => transaction.search(".description").text.strip.gsub("\r\n", " ").gsub("[", "").gsub("]", "").split(" ")[4]
      } if transaction.search(".credits").text.strip.gsub("\r\n", "") != ""
    end
    transaction_list
  end

  def transfer_funds(api_payment)
    navigate(:transfer_url)
    wallet_num_part1, wallet_num_part2 = split_wallet(wallet_num)

    @page = @page.form_with :id => "Form" do |f|
      f.Amount = amount
      f.TargetWalletNumberPart1 = wallet_num_part1
      f.TargetWalletNumberPart2 = wallet_num_part2
      f.Details = "#{id} #{domain}"
    end.submit
    sleep(20)

    code = get_transfer_validation_code(created_at)
    @page = @page.form_with :id => "Form" do |f|
      f.PayCode = code
    end.submit
    @page.search(".cab_content p")[0].text.strip == "Your Internal Payment has been processed"
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
    sms_list = SmsApi.get_sms_list
    code = nil
    sms_list.reverse.each do |sms|
      code = sms["message"].split("n").last.strip if sms["phone"] == "EPA" && (sms["sent"] + " +0400").to_datetime > request_created_at
    end
    raise EpaymentsException, "Unknown response code" if code.nil?
    code
  end

end
