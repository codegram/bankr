require 'spec_helper'

describe Bankr::Account do

  subject { Bankr::Account.new(:name => "Example account",
                               :number => "21000353110200123456",
                               :balance => "+5.300,00") }

  it { should respond_to(:name, :number, :balance) }

  context "initializes values from hash" do
    its(:name) { should == "Example account" }
    its(:number) { should == "21000353110200123456" }
    its(:balance) { should == "+5.300,00" }
  end

end
