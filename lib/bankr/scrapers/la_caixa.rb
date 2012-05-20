# encoding: utf-8
module Bankr
  module Scrapers
    class LaCaixa
      def initialize(options)

        @login = options[:login]
        @password = options[:password]

        Mechanize.html_parser = Nokogiri::HTML
        @agent = Mechanize.new

        @url = "http://m.lacaixa.es/apl/index_es.html"

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

        if page.link_with(text: 'Canviar idioma')
          page = agent.click page.link_with(:text => 'Canviar idioma')
          page = agent.click page.link_with(:text => 'Castellano')

        elsif page.link_with(text: 'Change language')
          page = agent.click page.link_with(:text => 'Change language')
          page = agent.click page.link_with(:text => 'Castellano')

        elsif page.link_with(text: 'Castellano')
          page = agent.click page.link_with(:text => 'Castellano')
        end

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

      # Scrapes the account list page for the accounts
      #
      def _accounts
        accounts = []
        
        page = navigate_to_accounts_index

        if page.content =~ /Saldo y movimientos/
          name = page.search("table").first.search("tr").search("td:nth-of-type(2)").text
          number = page.search("table.detalle").search("tr:nth-of-type(2)").search("td").text.delete(" ").delete("-")[0,20]
          balance = normalize_amount(page.search("form").search("div:nth-of-type(2)").search("table:nth-of-type(2)").search("td:nth-of-type(2)").text)
          accounts << Account.new(:name => name, :number => number, :balance => balance)
        else
          page.search('div:nth-of-type(2)').search('table:nth-of-type(2)').search('tr').each do |node|
            if node.search('td').length == 2 && !node.search('td:first a').text.empty?
              name = node.search('td:first a').text
              account_page = agent.click page.link_with(:text => name)
              number = account_page.search("form:nth-of-type(1) div.negritagris").text.gsub(/\D/,'')

              accounts << Account.new(:name => name,
                                      :number => number,
                                      :balance => normalize_amount(node.search('td:last').text))
            end
          end
        end
        accounts
      end

      def navigate_to_accounts_index
        page = if landing_page.link_with(text: 'Tesorería')
          agent.click landing_page.link_with(:text => 'Tesorería')
        else
          page = agent.click landing_page.link_with(:text => 'Todos')
          agent.click page.link_with(:text => 'Cuentas a la vista')
        end
      end

      def _movements_for(account, date = Time.now.to_date)
        raise ArgumentError, "Account must be specified" unless account.is_a?(Account)
        raise ArgumentError, "Date cannot be over 12 months ago" unless (date + 12.months) >= Time.now.to_date

        month_to_fetch = ((Time.now.to_date.to_time - date.to_time) / 60 / 60 / 24 / 30).to_i
        movements = []

        page = navigate_to_accounts_index

        # If we aren't in the account show, click the account name
        unless page.content.include?('Buscar por meses')
          page = agent.click page.link_with(:text => account.name)
        end

        # Navigate to the fetching month
        page.form.field_with(name: 'BUSCAR_MESES').options[month_to_fetch].select
        page = agent.submit(page.form)

        begin
          pagination = page.link_with(:text => '>> Más movimientos')
          movements += fetch_movements(page, account)

          # Navigate through pagination
          page = agent.click pagination if pagination
        end while pagination
        movements
      end

      private
      def fetch_movements(page, account)
        movements = []
        page.search("div:nth-of-type(3)").search('table:last').search('tr').each_slice(2) do |row|
          # Skip pagination link
          next if row.first.search('td').length != 2

          statement = row.first.search('td:first').text
          amount = row.first.search('td:last').text

          date = row.last.search('td div').text.match(/(\d{2})\/(\d{2})\/(\d{4})/)
          date = Date.parse(date[1] + '/' + date[2] + '/' + date[3]) if date

          movements << Movement.new(:account => account,
                                    :statement => statement,
                                    :amount => normalize_amount(amount),
                                    :date => date) unless statement.empty? or amount.empty?
        end
        movements
      end

      def normalize_amount(amount)
        amount.
          gsub('.','').
          gsub(',','.').
          to_f
      end

    end

    class CouldNotLogInException < StandardError
    end
    class NotLoggedInException < StandardError
    end

  end
end
