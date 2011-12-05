require 'spec_helper'

module Bankr
  module Outputs
    describe CSV do
      let(:account) { Account.new(number: "1234") }
      let(:movements) do
        movs = []
        Timecop.freeze(Date.civil(2011,11,11)) do
          movs = [
            Movement.new(
              :date    => Time.now.to_date,
              :account => account,
              :amount  => -20.51
            ),
            Movement.new(
              :date    => 3.months.ago,
              :account => account,
              :amount  => 8043.24
            ),
            Movement.new(
              :date    => 10.months.ago,
              :account => account,
              :amount  => -493.00
            )
          ]
        end
        movs
      end

      subject { CSV.new(movements) }

      it 'initializes with movements' do
        subject.instance_variable_get(:@movements).length.should eq(3)
      end

      describe '#filename' do
        it 'returns a filename with relevant data' do
          subject.filename.should eq("1234_2011-01_2011-11.csv")
        end
      end
    end
  end
end
