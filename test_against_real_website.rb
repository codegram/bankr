require 'bundler'
Bundler.setup
require 'pry'
require 'bankr'
require 'pp'
require 'yaml'

puts 'LaCaixa Scraper Live Test'
scraper = Bankr::Client.new('la_caixa', login: ENV['LOGIN'], password: ENV['PASSWORD'])
account_number = ENV['ACCOUNT_NUMBER']

puts 'Fetching movements for the last week...'
movements = scraper.movements_until(account_number, 1.week.ago)

puts "Fetched #{movements.size} movements."
puts movements.map(&:to_hash)
