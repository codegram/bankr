# -*- coding: utf-8 -*-
module Bankr
  module Scrapers
    class LaCaixa
      attr_reader :session, :url

      def initialize(options)
        @login = options[:login]
        @password = options[:password]

        @url = "https://empresa.lacaixa.es/home/empreses_ca.html"
        Capybara.default_max_wait_time = 10
        options = {
          js_errors: false
        }
        Capybara.register_driver :poltergeist do |app|
          driver = Capybara::Poltergeist::Driver.new(app, options)
          driver.headers =  {
            'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36'
          }
          driver
        end
        @session = Capybara::Session.new(:poltergeist)
      end

      def movements_until(iban, date = Date.today)
        raise "Date has to be in the past" if date > Date.today

        movements_from_to(iban, date, Date.today)
      rescue Exception => e
        path = "/tmp/#{Time.now}.png"
        session.save_screenshot(path, full: true)

        puts "---------------------------------------------------------------"
        puts "Something went wrong! The error message was:"
        puts e.message
        puts "Saved an screenshot at \"#{path}\""
        puts "---------------------------------------------------------------"
        exit(1)
      end

      def movements_from_to(iban, start_date, end_date)
        navigate_to_account(iban)
        inside_main_iframe do
          if session.has_link? 'Cercar moviments'
            session.click_link 'Cercar moviments'

            raise "Couldn't load search form" unless session.has_content?('Cerca avançada')
            session.find('#dia1').select(start_date.day.to_s.rjust(2, '0'))
            session.find('#mes1').select(start_date.month.to_s.rjust(2, '0'))
            session.find('#any1').select(start_date.year)

            session.find('#dia2').select(end_date.day.to_s.rjust(2, '0'))
            session.find('#mes2').select(end_date.month.to_s.rjust(2, '0'))
            session.find('#any2').select(end_date.year)

            session.click_link('Cercar')
            puts "Loading movements from #{start_date} to #{end_date} from #{iban}"

            begin
              if session.has_css?('a.next_acumulativo_on')
                session.find('a.next_acumulativo_on').click
                puts 'Opening movements...'
              end
            rescue Capybara::ElementNotFound, Capybara::Poltergeist::ObsoleteNode
            end while session.has_css?('a.next_acumulativo_on')
          else
            puts "There isn't the option to find movements between dates, loading the visible ones..."
          end

          if session.has_css?("#asincronoExtractos")
            movements = session.all('#asincronoExtractos .table_generica tbody tr').to_a.reverse
          elsif session.has_css?("#ListaCuentasBean01")
            movements = session.all('#ListaCuentasBean01 tr').to_a.reverse
            movements.pop
          end

          puts "Starting to parse #{movements.length} movements"

          parsed = []
          movements.each_with_index do |row, index|
            puts "Parsing movement #{index + 1}..."
            parsed << Movement.new(parse_movement(row))
          end
          parsed
        end
      rescue Capybara::Poltergeist::BrowserError => exception
        puts "Oooops something went wrong and Poltergeist crashed"
        puts exception.message
        puts exception.backtrace
        session.save_screenshot("/tmp/#{Time.now}.png", full: true)

        []
      end

      private

      def navigate_to_account(iban)
        log_in
        accounts_index
        puts "Loading account #{iban}.."
        inside_main_iframe do
          session.all('a')

          unless session.has_link?(iban)
            raise "Couldn't find account #{iban}"
          end

          session.click_link iban

          if !session.has_content?('Saldo actual') && !session.has_content?('Número de compte')
            raise "Couldn't load account #{iban}"
          end

          puts "Account loaded!"
        end
      end

      def log_in
        puts "Opening CaixaBank website..."
        session.visit(@url)
        session.find("#cookie-form .button a").click

        if session.has_no_content?("La teva privacitat")
          session.fill_in('usuari', with: @login)
          session.fill_in('password', with: @password)
          session.click_button 'Entrar'
        else
          raise "Couldn't dismiss cookie form"
        end

        if !session.has_css?('#Cabecera') || session.has_content?('IDENTIFICACIO INCORRECTA') || session.has_content?("Accés a Línia Oberta")
          raise "Couldn't login"
        else
          puts "Successfully logged in!"
        end
      end

      def accounts_index
        puts "Navigating to accounts index..."
        session.all('frameset')
        session.within_frame('Inferior') do
          session.all('frameset')
          session.within_frame('Niveles') do
            session.find('body')
            session.click_link 'Tresoreria'
          end
        end
        session.all('frameset')
        session.within_frame('Inferior') do
          session.all('frameset')
          session.within_frame('Menu') do
            session.find('body')
            # session.click_link 'Posició'
          end
        end
      end

      def inside_main_iframe(&block)
        session.all('frameset')
        session.within_frame('Inferior') do
          session.all('frameset')
          session.within_frame('Cos') do
            session.find('body')
            yield block
          end
        end
      end

      def parse_movement(row)
        return parse_basic_movement(row) if session.has_content?('Internacional')

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
        puts "Oops something went wrong when expanding a detail view"
        puts row.inspect
        return attributes if defined?(attributes)
      end

      def parse_basic_movement(row)
        values = row.all('td').map(&:text)
        {
          "Concepte" => values[3],
          "Data" => values[0],
          "Data valor" => values[1],
          "Import" => values[4],
          'balance' => values[5]
        }
      end
    end
  end

  class CouldNotLogInException < StandardError
  end
end
