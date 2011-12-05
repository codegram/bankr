require 'nokogiri'
require 'mechanize'
require 'active_support'
require 'active_support/time'

require 'bankr/scrapers/la_caixa'
require 'bankr/outputs/csv'

module Bankr

  class Bankr

    def initialize(options)
      @scraper = eval("Scrapers::#{options.delete(:bank)}").new(options)
    end

    def logged_in?
      @scraper.logged_in?
    end

  end

end
