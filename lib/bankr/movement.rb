module Bankr
  class Movement
    attr_accessor :account, :statement, :amount, :date

    def initialize(options)
      @account   = options[:account]
      @statement = options[:statement]
      @amount    = options[:amount]
      @date      = options[:date]
    end
  end
end
