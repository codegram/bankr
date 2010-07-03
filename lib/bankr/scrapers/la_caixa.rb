require 'nokogiri'
require 'mechanize'

module Bankr
  module Scrapers
    class LaCaixa
      def initialize(options)

        @login = options[:login]
        @password = options[:password]

        @logged_in = false

      end

      def logged_in?
        @logged_in
      end

      def log_in
        Mechanize.html_parser = Nokogiri::HTML
        agent = Mechanize.new

        url = 'http://mobil.lacaixa.es/'

        page = agent.get(url)
        page = agent.click page.link_with(:text => 'Castellano') if page.link_with(:text => 'Castellano')
        page = agent.click page.link_with(:text => 'Línea Abierta')

        login_form = page.forms[1]
        login_form.E = @login
        login_form.B = @password
        page = agent.submit(login_form)

        if page.body =~ /Cuenta principal/
          @logged_in = true 
        else
          raise Scrapers::CouldNotLogInException
        end

        populate_attributes_from(page)

        main_account_name = page.search('div:nth-of-type(2)').search('table:nth-of-type(2)').search('td:first').search('a').text

        main_account_balance = page.search('div:nth-of-type(2)').search('table:nth-of-type(2)').search('td:nth-of-type(2)').search('font').text

      end

      def main_account_balance
        @main_account_balance ||= main_account_balance!
      end

    end

    class CouldNotLogInException < StandardError
    end

  end
end
