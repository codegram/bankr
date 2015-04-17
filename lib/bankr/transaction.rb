module Bankr
  class Transaction
    include Bankr::Helpers

    def initialize(payload)
      @payload = payload
    end

    def statement
      [
        @payload["Concepto transferencia:"],
        @payload["Concepto:"],
        " ",
        @payload["Concepto de la trasnferencia:"],
        @payload["Concepto de transferencia:"],
        @payload["Concepto específico:"],
        " ",
        @payload["Primer concepto del recibo:"],
        @payload["Referencia recibo sepa:"],
        @payload["Ampliacion concepto transferencia:"],
      ].compact.uniq.join.strip
    end

    def date
      @date ||= Date.parse(@payload["Fecha:"])
    end

    def value_date
      @value_date ||= Date.parse(@payload["Fecha valor:"])
    end

    def remitter
      [
        @payload["Nombre completo del ordenante:"],
        @payload["Remitente:"],
        @payload["Ampliacion remitente de la transferencia:"],
        @payload["Ampliacion remitente transferencia:"],
        " ",
        @payload["Direccion remitente:"],
        @payload["Poblacion remitente:"],
      ].compact.uniq.join.strip
    end

    def recipient
      [
        @payload["Beneficiario:"],
        @payload["Nombre del beneficiario:"],
        @payload["Titular del recibo:"],
      ].compact.uniq.join
    end

    def recipient_account
      @payload["Cuenta destino:"]
    end

    def amount
      @amount ||= normalize_amount(@payload["Importe:"])
    end

    def bank_branch
      @payload["Oficina:"]
    end

    def iban
      @payload["Nº cuenta:"]
    end

    def scrape_index
      @payload[:scrape_index]
    end

    def <=>(other)
      srape_index <=> other.scrape_index
    end

    def hash
      @hash ||= Digest::MD5.hexdigest([
        @payload["Importe:"],
        @payload["Fecha"],
        @payload["Fecha valor"],
        @payload["Concepto:"],
      ].join('|'))
    end

    def inspect
      "#<Bankr::Transaction:#{hash}
  statement: #{statement},
  date: #{date},
  value_date: #{value_date},
  remitter: #{remitter},
  recipient: #{recipient},
  recipient_account: #{recipient_account},
  amount: #{amount},
  bank_branch: #{bank_branch},
  iban: #{iban},
  scrape_index: #{scrape_index},
>"
    end
  end
end
