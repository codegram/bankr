require 'bundler'
Bundler.setup
require 'bankr'

VALID_DATA = YAML.load( File.open('spec/support/valid_data.yml') )

a = Bankr::Scrapers::LaCaixa.new(:login => VALID_DATA["login"], :password => VALID_DATA["password"])

puts "LaCaixa Scraper Live Test"
puts "Logging in...."
a.log_in
puts "...ok"

puts "Fetching accounts...."
accounts = a.accounts
puts "...ok. #{accounts.size} accounts found."

puts "Fetching first account..."
first_account = accounts[0]
puts "...ok" unless first_account.nil?

puts "Fetching movements for the current month..."
movements = a._movements_for(first_account, 3.months.ago)
puts movements.inspect
puts "...ok. Fetched #{movements.size} movements." unless movements.empty? or movements.nil?

puts "Just for the record, your last movement looks like this:"
pp movements.last

puts "All movements statements:"
pp movements.map(&:statement)
