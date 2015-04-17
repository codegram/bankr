require 'nokogiri'
require 'mechanize'
require 'active_support'
require 'active_support/time'

require 'bankr/scrapers/la_caixa'
require 'bankr/outputs/csv'

module Bankr
  class Client
    def initialize(bank, scraper_options)
      @scraper = "Scraper::#{bank.classify}".constanntize.new(scraper_options)
    end

    def transaction_until(date = Time.now.to_date)
    end
  end
end
