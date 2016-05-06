module Bankr
  class Client
    def initialize(bank, scraper_options)
      @scraper = "Bankr::Scrapers::#{bank.classify}".constantize.new(scraper_options)
    end

    def movements_until(iban, date)
      @scraper.movements_until(iban, date)
    end

    def movements_from_to(iban, start_date, end_date)
      @scraper.movements_from_to(iban, start_date, end_date)
    end
  end
end
