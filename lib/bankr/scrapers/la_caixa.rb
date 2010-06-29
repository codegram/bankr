module Bankr
  module Scrapers
    class LaCaixa
      def initialize(options)

        @login = options[:login]
        @password = options[:password]

        @logged_in = false

      end

      def logged_in?
        @logged_in
      end

      def log_in
        @logged_in = true
      end

    end
  end
end
