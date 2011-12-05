require 'csv'

module Bankr
  module Outputs
    class CSV
      def initialize(movements)
        @movements = movements
      end

      def write
        p "Exporting #{filename}"
        CSV.open(filename, "wb") do |csv|
          movements.each do |movement|
            csv << [
              movement.date,
              movement.amount,
              movement.statement
            ]
          end
        end
      end

      def filename
        date_format = "%Y-%m"
        first_date = @movements.first.date.strftime(date_format)
        last_date  = @movements.last.date.strftime(date_format)
        number     = @movements.first.account.number

        "#{number}_#{last_date}_#{first_date}.csv"
      end
    end
  end
end
