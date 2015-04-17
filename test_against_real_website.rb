require 'bundler'
Bundler.setup
require 'pry'
require 'bankr'
require 'pp'
require 'yaml'

puts "LaCaixa Scraper Live Test"
VALID_DATA = YAML.load( File.open('spec/support/valid_data.yml') )
scraper = Bankr::Scrapers::LaCaixa.new(:login => VALID_DATA["login"], :password => VALID_DATA["password"])

puts "Fetching accounts...."
accounts = scraper.accounts

if accounts.any?
  puts "#{accounts.size} accounts found!"

  accounts.each do |account|
    puts [account.name, account.iban, account.balance.to_f].join(' - ')
  end

  account = accounts[1]
  puts "Fetching transactions for the current month..."
  transactions = account.transactions_until(Time.now.to_date)

  puts "Fetched #{transactions.size} transactions."

  binding.pry
else
  puts "No accounts found"
end

#
# puts "Just for the record, your last transaction looks like this:"
# pp transactions.last
#
# puts "All transactions statements:"
# pp transactions.map(&:statement)
#
# csv = Bankr::Outputs::CSV.new(transactions)
# p "Exporting transactions to #{csv.filename}..."
# csv.write
# system("cat #{csv.filename}")
