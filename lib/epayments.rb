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

  def transfer_funds(options)
    navigate(:transfer_url)
    wallet_num_part1, wallet_num_part2 = split_wallet(options[:to])

    @page = @page.form_with :id => "Form" do |f|
      f.Amount = options[:amount]
      f.TargetWalletNumberPart1 = wallet_num_part1
      f.TargetWalletNumberPart2 = wallet_num_part2
      f.Details = "#{options[:id]} #{options[:domain]}"
    end.submit

    @page = @page.form_with(:id => "Form").submit

    if @page.search(".cab_content p")[0].text.strip == "Your Internal Payment has been processed"
      true
    else
      raise EpaymentsException, @page.search(".cab_content p")[0].text
    end
  end

  def balance
    @page.search(".card_money span strong").first.text.to_f
  end

  private

  def navigate(location)
    @page = @agent.get("https://#{SERVICE_URL}/#{LOCATIONS[location]}")
  end

  def save_current_page(name="Page#{Time.now.to_i}.html")
    @page.save("#{name}.html")
  end

  def split_wallet(wallet_num)
    wallet_num.split("-")
  end

end
