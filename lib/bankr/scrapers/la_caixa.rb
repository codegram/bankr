# encoding: utf-8
module Bankr
  module Scrapers
    class LaCaixa
      def initialize(options)

        @login = options[:login]
        @password = options[:password]

        Mechanize.html_parser = Nokogiri::HTML
        @agent = Mechanize.new

        @url = 'http://mobil.lacaixa.es/'

        @logged_in = false

      end

      def agent
        @agent
      end

      def logged_in?
        @logged_in
      end

      def landing_page
        raise Scrapers::NotLoggedInException unless @landing_page
        @landing_page
      end

      def log_in

        page = agent.get(@url)
        page = agent.click page.link_with(:text => 'Castellano') if page.link_with(:text => 'Castellano')
        page = agent.click page.link_with(:text => 'Línea Abierta')

        login_form = page.forms[1]
        login_form.E = @login
        login_form.B = @password
        page = agent.submit(login_form)

        if page.body =~ /Cuenta principal/
          @logged_in = true 
          @landing_page = page
        else
          raise Scrapers::CouldNotLogInException
        end

        true

      end

      def accounts
        @accounts ||= _accounts
      end

      def _accounts
        accounts = []

        page = agent.click landing_page.link_with(:text => 'Cuentas')

        page.search('div:nth-of-type(2)').search('table:nth-of-type(2)').search('tr').each do |node|
          unless node.search('td:first a').text.empty? then
            accounts << Account.new(:name => node.search('td:first a').text,
                                    :url => node.search('td:first a').attribute('href').value,
                                    :balance => node.search('td:last font').text)
          end
        end
        accounts
      end

      def _movements_for(account, options = {})
        raise ArgumentError, "Account must be specified" unless account.is_a?(Account)
        timespan = 2.weeks
        timespan = options[:last] if options[:last]

        movements = []
        
        page = agent.click landing_page.link_with(:text => 'Cuentas')

        page = agent.click page.link_with(:text => account.name)

        begin
          pagination = page.link_with(:text => '>> Ver más movimientos')
          div_number = page.search('div:nth-of-type(5)').empty? ? '3' : '4'

          page.search("div:nth-of-type(#{div_number})").search('table:last').search('tr').each_slice(2) do |row|
            statement = row.first.search('td:first a').text
            amount = row.first.search('td:last font').text

            date = row.last.search('td div').text.match(/(\d{2})\/(\d{2})\/(\d{4})/)
            date = Date.parse(date[2] + '/' + date[1] + '/' + date[3]) if date

            return movements if date and date < timespan.send(:ago).to_date

            movements << Movement.new(:account => account,
                                        :statement => statement,
                                        :amount => amount,
                                        :date => date) unless statement.empty? or amount.empty?
          end

          # Navigate through pagination
          page = agent.click pagination if pagination
        end while pagination
        movements
      end

    end

    class CouldNotLogInException < StandardError
    end
    class NotLoggedInException < StandardError
    end

  end
end
