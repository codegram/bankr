require 'spec_helper'

describe Bankr::Movement do

  subject { Bankr::Movement.new(:account => mock('account', :name => 'Main account'),
                                :statement => "Burger King",
                                :amount => "-9,95",
                                :date => '10/23/2009') }

  it { should respond_to(:account, :statement, :amount, :date) }

  context "initializes values from hash" do

    it "assigns the account" do
      subject.account.name.should == 'Main account'
    end
    its(:statement) { should == "Burger King" }
    its(:amount) { should == "-9,95" }
    its(:date) { should == "10/23/2009" }

  end

end
