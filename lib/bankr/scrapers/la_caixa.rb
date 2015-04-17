module Bankr
  module Scrapers
    class LaCaixa
      attr_reader :agent

      def initialize(options)
        @login = options[:login]
        @password = options[:password]

        Mechanize.html_parser = Nokogiri::HTML
        @agent = Mechanize.new
        @url = "https://webm.lacaixa.es/home/menu_es.html"
      end

      def accounts
        @accounts ||= accounts_index.links_with(search: 'div:nth-of-type(2) table:nth-of-type(2) tr td:first a').map do |link|
          page = link.click
          page.encoding = 'utf-8'
          Account.new(page)
        end
      end

      private

      def accounts_index
        @accounts_index ||= if landing_page.link_with(text: 'Tesorería')
                             landing_page.link_with(text: 'Tesorería').click
                           else
                             page = landing_page.link_with(text: 'Todos').click
                             page.link_with(text: 'Cuentas a la vista').click
                           end
      end

      def landing_page
        return @landing_page if defined?(@landing_page)

        page = agent.get(@url)

        if page.link_with(text: 'Canviar idioma')
          page = page.link_with(:text => 'Canviar idioma').click
          page = page.link_with(:text => 'Castellano').click

        elsif page.link_with(text: 'Change language')
          page = page.link_with(:text => 'Change language').click
          page = page.link_with(:text => 'Castellano').click

        elsif page.link_with(text: 'Castellano')
          page = page.link_with(:text => 'Castellano').click
        end

        page = page.link_with(text: /Línea Abierta/).click

        login_form = page.forms[1]

        login_form.E = @login
        login_form.B = @password

        @landing_page = agent.submit(login_form)
        @landing_page.encoding = 'utf-8'

        unless @landing_page.body =~ /Desconectar/
          raise Scrapers::CouldNotLogInException
        end

        @landing_page
      end
    end

    class CouldNotLogInException < StandardError
    end
  end
end
