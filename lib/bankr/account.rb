module Bankr
  class Account
    attr_accessor :name, :number, :balance

    def initialize(options)
      @name    = options[:name]
      @balance = options[:balance]
      @number  = options[:number]
    end
  end
end
