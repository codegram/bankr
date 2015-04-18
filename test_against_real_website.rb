require 'bundler'
Bundler.setup
require 'pry'
require 'bankr'
require 'pp'
require 'yaml'

puts "LaCaixa Scraper Live Test"
VALID_DATA = YAML.load( File.open('spec/support/valid_data.yml') )
scraper = Bankr::Client.new('la_caixa', login: VALID_DATA["login"], password: VALID_DATA["password"])

account_number = VALID_DATA['iban']

puts "Fetching movements for the current month..."
movements = scraper.movements_until(account_number, Date.parse('01/11/2015'))

puts "Fetched #{movements.size} movements."
