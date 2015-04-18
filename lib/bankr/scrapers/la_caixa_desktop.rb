module Bankr
  module Scrapers
    class LaCaixaDesktop
      attr_reader :session, :url

      def initialize(options)
        @login = options[:login]
        @password = options[:password]

        @url = "https://empresa.lacaixa.es/home/empreses_ca.html"
        # Capybara.default_wait_time = 10
        Capybara.register_driver :selenium_firefox do |app|
          client = Selenium::WebDriver::Remote::Http::Default.new
          Capybara::Selenium::Driver.new(app, :browser => :firefox, :http_client => client)
        end
        @session = Capybara::Session.new(:selenium_firefox)

        # @session.driver.header('User-Agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.82 Safari/537.36')
        # @session.driver.allow_url('*')
      end

      def landing_page
        session.visit(@url)
        session.fill_in('usuari', with: @login)
        session.fill_in('password', with: @password)
        session.click_button 'Entrar'

        if session.has_css?('#Cabecera')
          session.driver.browser.switch_to.frame('Inferior')
          session.driver.browser.switch_to.frame('Niveles')
          session.click_link 'Tresoreria'
          session.driver.browser.switch_to.default_content

          session.driver.browser.switch_to.frame('Inferior')
          session.driver.browser.switch_to.frame('Cos')

          accounts = session.all('#lo_contenido table.table_generica tr#data').map do |row|
            {
              iban: row.find('th').text,
              name: row.find('td.ltxt:nth-of-type(2)').text,
              balance: row.find('td.rtxt').text,
            }
          end

          session.click_link accounts.first[:iban]

          if session.has_content?('Saldo actual')
            session.click_link 'Cercar moviments'

            if session.has_content?('Cerca avançada')
              session.find('#dia1').select('01')
              session.find('#mes1').select('03')
              session.find('#any1').select('2015')

              session.find('#dia2').select('31')
              session.find('#mes2').select('03')
              session.find('#any2').select('2015')

              session.click_link('Cercar')

              begin
                if session.has_css?('a.next_acumulativo_on')
                  session.find('a.next_acumulativo_on').click
                end
              rescue Capybara::ElementNotFound
              end while session.has_css?('a.next_acumulativo_on')

              session.all('#asincronoExtractos .table_generica tbody tr').map do |row|
                row.find('th.ltxt a').click
                detail = session.find('#' + row['id'] + 'Oculta')
                if detail.has_content?('Veure detall')
                  detail.click_link('Veure detall')
                end

                if detail.has_css?('.detalle_info')
                  detail.all('.detalle_info .table_resumen tr').select do |attribute_row|
                    attribute_row.all('td.rtxt').any?
                  end.inject({}) do |attributes, attribute_row|
                    attributes.update(attribute_row.find('td.rtxt').text => attribute_row.find('td.ltxt').text)
                  end
                end
              end
            end
          end
        end
      end
    end

    class CouldNotLogInException < StandardError
    end
  end
end
