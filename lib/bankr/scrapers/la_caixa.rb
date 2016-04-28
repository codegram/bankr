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

        movements_from_to(iban, date, Date.today)
      end

      def movements_from_to(iban, start_date, end_date)
        navigate_to_account(iban)
        inside_main_iframe do
          session.click_link 'Cercar moviments'

          raise "Couldn't load search form" unless session.has_content?('Cerca avançada')
          session.find('#dia1').select(start_date.day.to_s.rjust(2, '0'))
          session.find('#mes1').select(start_date.month.to_s.rjust(2, '0'))
          session.find('#any1').select(start_date.year)

          session.find('#dia2').select(end_date.day.to_s.rjust(2, '0'))
          session.find('#mes2').select(end_date.month.to_s.rjust(2, '0'))
          session.find('#any2').select(end_date.year)

          session.click_link('Cercar')
          puts "Loading movements from #{start_date} to #{end_date}"

          begin
            if session.has_css?('a.next_acumulativo_on')
              session.find('a.next_acumulativo_on').click
              puts 'Opening movements...'
            end
          rescue Capybara::ElementNotFound, Capybara::Poltergeist::ObsoleteNode
          end while session.has_css?('a.next_acumulativo_on')

          movements = session.all('#asincronoExtractos .table_generica tbody tr').to_a.reverse

          puts "Starting to parse #{movements.length} movements"

          movements.map do |row|
            Movement.new(parse_movement(row))
          end
        end
      rescue Capybara::Poltergeist::BrowserError => exception
        puts "Oooops something went wrong and Poltergeist crashed"
        puts exception.message
        session.save_screenshot("/tmp/#{Time.now}.png", full: true)
      end

      private

      def navigate_to_account(iban)
        log_in
        accounts_index
        inside_main_iframe do
          session.all('a')
          unless session.has_link?(iban)
            raise "Couldn't find account #{iban}"
          end
          session.click_link iban
          unless session.has_content?('Saldo actual')
            raise "Couldn't find account #{iban}"
          end
        end
      end

      def log_in
        session.visit(@url)
        session.fill_in('usuari', with: @login)
        session.fill_in('password', with: @password)
        session.click_button 'Entrar'

        if !session.has_css?('#Cabecera') || session.has_content?('IDENTIFICACIO INCORRECTA') || session.has_content?("Accés a Línia Oberta")
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
        session.find('body')
        session.within_frame('Inferior') do
          session.find('body')
          session.within_frame('Cos') do
            session.find('body')
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

        attributes = {
          "Concepte" => basic_detail.search('th span a').text,
          "Data" => basic_detail.search('td.ltxt').first.text,
          "Import" => basic_detail.search('td.rtxt')[1].text,
          'balance' => balance,
        }

        if detail.has_css?('.detalle_info')
          table = detail.find('.detalle_info .table_resumen')

          table.all('tr').select do |attribute_row|
            attribute_row.all('td.rtxt').any?
          end.each do |attribute_row|
            attributes.update(attribute_row.first('td.rtxt').text => attribute_row.first('td.ltxt').text)
          end
        end

        attributes
      rescue Capybara::ElementNotFound
        nil
      end
    end
  end

  class CouldNotLogInException < StandardError
  end
end
