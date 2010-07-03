require 'spec_helper'

describe Bankr::Scrapers::LaCaixa do

  subject { Bankr::Scrapers::LaCaixa.new(:login => VALID_DATA["login"], :password => VALID_DATA["password"])}

  it { should respond_to(:log_in) }

  describe "#log_in" do

    it "successfully logs in with valid authentication data" do
      pending
      expect {
        subject.log_in
      }.to change(subject, :logged_in?).from(false).to(true)
    end

    it "fails to log in and raises and exception with invalid authentication data" do
      pending
      scraper = Bankr::Scrapers::LaCaixa.new(:login => '33358924',
                                             :password => '3333') 
      expect {
        scraper.log_in
      }.to raise_error(Bankr::Scrapers::CouldNotLogInException)
      scraper.logged_in?.should be_false
    end

  end

  context "public getters with cache" do

    it { should respond_to(:main_account_balance) }

    describe "#main_account_balance" do

      it "fetches the main account balance and caches it" do
        subject.stub(:main_account_balance!).and_return('1.200', '1.400')
        subject.main_account_balance.should == '1.200'
        # Even though main_account_balance! has changed, it should return the cached value
        subject.main_account_balance.should == '1.200'
      end

    end

  end

end
