module Bankr

  class Account

    include ::ActiveModel::Validations
    include ::ActiveModel::Serialization

    validates_presence_of :name, :balance

    attr_accessor :name, :url, :balance

    def initialize(options)
      @attributes = options

      @name = options[:name]
      @url = options[:url]
      @balance = options[:balance]
    end

    def read_attribute_for_validation(key)
      @attributes[key]
    end

  end 

end
