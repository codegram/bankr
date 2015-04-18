module Bankr
  module Scrapers
    class LaCaixa
      attr_reader :session, :url

      def initialize(options)
        @login = options[:login]
        @password = options[:password]

        @url = "https://empresa.lacaixa.es/home/empreses_ca.html"
        Capybara.default_wait_time = 4
        Capybara.register_driver :poltergeist do |app|
          Capybara::Poltergeist::Driver.new(app, js_errors: false)
        end
        @session = Capybara::Session.new(:poltergeist)
      end

      def movements_until(iban, date = Date.today)
        raise "Date has to be in the past" if date > Date.today

        navigate_to_account(iban)
        inside_main_iframe do
          session.click_link 'Cercar moviments'

          raise "Couldn't load search form" unless session.has_content?('Cerca avançada')
          session.find('#dia1').select(date.day.to_s.rjust(2, '0'))
          session.find('#mes1').select(date.month.to_s.rjust(2, '0'))
          session.find('#any1').select(date.year)

          session.find('#dia2').select(Date.today.day.to_s.rjust(2, '0'))
          session.find('#mes2').select(Date.today.month.to_s.rjust(2, '0'))
          session.find('#any2').select(Date.today.year)

          session.click_link('Cercar')
          puts "Loading movements from #{date} to #{Date.today}"

          begin
            if session.has_css?('a.next_acumulativo_on')
              session.find('a.next_acumulativo_on').click
              puts 'Opening movements...'
            end
          rescue Capybara::ElementNotFound, Capybara::Poltergeist::ObsoleteNode#, Selenium::WebDriver::Error::StaleElementReferenceError
            session.save_screenshot('pagination.png')
          end while session.has_css?('a.next_acumulativo_on')

          movements = session.all('#asincronoExtractos .table_generica tbody tr').to_a.reverse

          puts "Starting to parse #{movements.length} movements"

          movements.map do |row|
            Movement.new(parse_movement(row)).save
          end
        end
      end

      private

      def navigate_to_account(iban)
        log_in
        accounts_index
        inside_main_iframe do
          session.click_link iban
          unless session.has_content?('Saldo actual')
            raise "Couldn't find account #{iban}"
          end
        end
      end

      def log_in
        session.visit(@url)
        session.fill_in('usuari', with: '73365148900')
        session.fill_in('password', with: '906090')
        session.click_button 'Entrar'

        if !session.has_css?('#Cabecera') || session.has_content?('IDENTIFICACIO INCORRECTA')
          raise "Couldn't login"
        end
      end

      def accounts_index
        session.within_frame('Inferior') do
          session.within_frame('Niveles') do
            session.click_link 'Tresoreria'
          end
        end
      end

      def inside_main_iframe(&block)
        session.within_frame('Inferior') do
          session.within_frame('Cos') do
            yield block
          end
        end
      end

      def parse_movement(row)
        row.find('th.ltxt a').click
        detail = session.find('#' + row['id'] + 'Oculta')

        if detail.has_content?('Veure detall')
          detail.click_link('Veure detall')
        end

        basic_detail = Nokogiri::HTML(session.driver.evaluate_script("document.getElementById('#{row['id']}').innerHTML"))
        balance = basic_detail.search('td.rtxt')[2].text

        if detail.has_css?('.detalle_info')
          table = detail.find('.detalle_info .table_resumen')
          html = Nokogiri::HTML(session.driver.evaluate_script("document.getElementById('#{table['id']}').innerHTML"))

          html.search('tr').select do |attribute_row|
            attribute_row.search('td.rtxt').any?
          end.inject({'balance' => balance}) do |attributes, attribute_row|
            attributes.update(attribute_row.search('td.rtxt').text => attribute_row.search('td.ltxt').text)
          end
        else
          return {
            "Concepte" => basic_detail.search('th span a').text,
            "Data" => basic_detail.search('td.ltxt').first.text,
            "Import" => basic_detail.search('td.rtxt')[1].text,
            'balance' => balance,
          }
        end
      rescue Capybara::ElementNotFound
        nil
      end
    end
  end

  class CouldNotLogInException < StandardError
  end
end
