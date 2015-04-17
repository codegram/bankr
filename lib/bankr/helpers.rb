require 'bigdecimal'
module Bankr
  module Helpers
    def normalize_amount(amount)
      BigDecimal.new(amount.gsub('.','').gsub(',','.'))
    end
  end
end
