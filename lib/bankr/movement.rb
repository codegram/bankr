require 'gdbm'

module Bankr
  class Movement
    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def statement
      [
        merge_fields("Concepte", "Continuació del Concepte"),
        " ",
        merge_fields("Concepte transferencia", "Concepte traspas", "Concepte de la transferencia"),
        " ",
        merge_fields("Concepte específic", "Concepte informat per l'ordenant", "Referència Ordenant de la transferència", "Referència pel beneficiari"),
        " ",
        merge_fields("Primer concepte del rebut", "Ampliacio concepte transferencia"),
      ].join.strip.gsub('  ', ' ')
    end

    def credit_card_number
      @payload["Referència2"].scan(/[0-9]{4}/).join(' ') if @payload["Concepte"] == 'COMPRA AMB TARGETA'
    end

    def date
      @date ||= DateTime.parse(@payload["Data"] + ' ' + @payload['Hora'].to_s)
    end

    def value_date
      @value_date ||= Date.parse(@payload["Data valor"].to_s)
    rescue ArgumentError
      nil
    end

    def remitter
      [
        merge_fields("Nom de l'ordenant", "Nom sencer de l'ordenant", "Nom del Creditor", "Remitent"),
        " ",
        merge_fields("Ampliacio remitent de la transferencia", "Ampliacio remitent transferencia"),
        " ",
        merge_fields("Adreca remitent", "Poblacio remitent"),
      ].join.strip.gsub('  ', ' ')
    end

    def recipient
      [
        merge_fields("Beneficiari", "Nom del beneficiari", "Titular del rebut", "Nom Deutor"),
        " ",
        @payload["Domicili beneficiari"],
      ].join.strip.gsub('  ', ' ')
    end

    def recipient_account
      @payload["Compte desti"]
    end

    def amount
      @amount ||= normalize_amount(@payload["Import"])
    end

    def balance
      @balance ||= normalize_amount(@payload['balance'])
    end

    def bank_branch
      @payload["Oficina"].to_s.strip.split.join(' ')
    end

    def iban
      @payload["Número de compte (IBAN)"]
    end

    def <=>(other)
      date <=> other.date
    end

    def signature
      @signature ||= Digest::MD5.hexdigest([
        @payload["Número de compte (IBAN)"],
        @payload["Import"],
        @payload["Data"],
        @payload["Hora"],
        @payload["Concepte"],
      ].join('|'))
    end

    def inspect
      "#<Bankr::Movement:#{signature}
  statement: #{statement},
  date: #{date},
  value_date: #{value_date},
  credit_card_number: #{credit_card_number},
  remitter: #{remitter},
  recipient: #{recipient},
  recipient_account: #{recipient_account},
  amount: #{amount.to_f},
  bank_branch: #{bank_branch},
  iban: #{iban}
>"
    end

    def save
      db = GDBM.new('movements.db')
      db[signature] = Marshal.dump(payload)
      db.close
    end

    def to_hash
      {
        signature: signature,
        statement: statement,
        credit_card_number: credit_card_number,
        date: date,
        value_date: value_date,
        remitter: remitter,
        recipient: recipient,
        recipient_account: recipient_account,
        amount: amount.to_f,
        balance: balance.to_f,
        bank_branch: bank_branch,
        iban: iban
      }.inject({}) do |hash, (k,v)|
        v = nil if v.to_s.empty?
        hash[k] = v
        hash
      end
    end

    private

    def merge_fields(*fields)
      merge = fields.map do |field|
        @payload[field]
      end.compact.uniq.join.strip

      return nil if merge == ''
      merge
    end

    def normalize_amount(value)
      BigDecimal.new(value.to_s.gsub('.','').gsub(',','.').each_char.select{|c| c.present?}.join)
    end
  end
end
