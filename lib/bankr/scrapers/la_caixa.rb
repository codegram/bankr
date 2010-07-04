require 'nokogiri'
require 'mechanize'

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

    end

    class CouldNotLogInException < StandardError
    end
    class NotLoggedInException < StandardError
    end

  end
end
