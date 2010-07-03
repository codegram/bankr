module Bankr

  class Account

    attr_accessor :name, :url, :balance

    def initialize(options)
      @name = options[:name]
      @url = options[:url]
      @balance = options[:balance]
    end

  end 

end
