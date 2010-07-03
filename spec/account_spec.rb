require 'spec_helper'

describe Bankr::Account do

  subject { Bankr::Account.new(:name => "Example account",
                               :url => "http://www.bank.com/accounts/3847298",
                               :balance => "+5.300,00") }

  it { should respond_to(:name, :url, :balance) }

  context "initializes values from hash" do

    its(:name) { should == "Example account" }
    its(:url) { should == "http://www.bank.com/accounts/3847298" }
    its(:balance) { should == "+5.300,00" }

  end

end
