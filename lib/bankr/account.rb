module Bankr
  class Account
    include Bankr::Helpers

    def initialize(account_page)
      @account_page = account_page
    end

    def name
      @name ||= @account_page.search('table')[0].search('td:last').text
    end

    def iban
      @iban ||= @account_page.body.scan(/[a-zA-Z]{2}[0-9]{2} [0-9]{4} [0-9]{4} [0-9]{4} [0-9]{4}/).first
    end

    def balance
      @balance ||= normalize_amount(@account_page.search('table')[3].search('td:last').text)
    end

    def transactions_until(date_or_transaction_hash)
      date = date_or_transaction_hash
      raise ArgumentError, "Date cannot be over 12 months ago" unless (date + 12.months) >= Time.now.to_date

      month_to_fetch = ((Time.now.to_date.to_time - date.to_time) / 60 / 60 / 24 / 30).to_i

      # If we aren't in the account show, click the account name
      unless @account_page.content.include?('Buscar por meses')
        @account_page = page.link_with(text: account.name).click
      end

      # Navigate to the fetching month
      @account_page.form.field_with(name: 'BUSCAR_MESES').options[month_to_fetch].select
      month_page = @account_page.form.submit

      transactions(month_page)
    end

    private

    def transactions(month_page)
      transactions = []
      scrape_index = 0

      begin
        month_page.encoding = 'utf-8'

        month_page.search('table:nth-of-type(2) tr').select do |node|
          !node.text.include?(">> Más movimientos")
        end.select do |node|
          node.search('td').count == 2
        end.each do |transaction|
          href = transaction.search('td a').first['href']
          transaction_page = month_page.link_with(href: href).click
          transaction_page.encoding = 'utf-8'

          payload = transaction_page.search('table')[0].search('tr').each_slice(2).inject({}) do |attributes, attribute|
            attributes.update(attribute.first.text => attribute.last.text)
          end

          transactions << Transaction.new(payload.merge(scrape_index: scrape_index))
          scrape_index += 1
        end

        pagination = month_page.link_with(text: /Más movimientos/)
        month_page = pagination.click if pagination
      end while pagination

      transactions
    end
  end
end
