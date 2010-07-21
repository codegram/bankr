module Bankr

  class Movement

    include ::ActiveModel::Validations
    include ::ActiveModel::Serialization

    validates_presence_of :account, :statement, :amount, :date

    attr_accessor :account, :statement, :amount, :date

    def initialize(options)
      @attributes = options

      @account = options[:account] 
      @statement = options[:statement] 
      @amount = options[:amount] 
      @date = options[:date] 
    end

  end

end
