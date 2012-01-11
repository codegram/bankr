require 'bundler'
Bundler.setup
require 'bankr'

class CustomBankr

  def initialize
    login
  end

  def scraper
    @scraper ||= Bankr::Scrapers::LaCaixa.new(login: valid_data["login"],
                                              password: valid_data["password"])
  end

  def accounts
    scraper.accounts
  end

  def movements(date = Time.now.to_date)
    puts "Fetching movements for: #{date}"
    accounts.each do |account|
      movements = scraper._movements_for(account, date)
      export(movements) if movements.any?
    end
  end

  private
  def export(movements)
    csv = Bankr::Outputs::CSV.new(movements)
    puts "Exporting movements to #{csv.filename}..."
    csv.write
    system("cat #{csv.filename}")
  end

  def login
    scraper.log_in
  end

  def valid_data
    @yaml ||= YAML.load( File.open('spec/support/valid_data.yml') )
  end
end

past_month = (Time.now - (1 * 30 * 24 * 60 * 60)).to_date

bankr = CustomBankr.new
bankr.movements(past_month)
bankr.movements
