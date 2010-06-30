require 'spec_helper'

describe Bankr::Scrapers::LaCaixa do

  subject { Bankr::Scrapers::LaCaixa.new(:login => VALID_DATA["login"], :password => VALID_DATA["password"])}

  it { should respond_to(:log_in) }

  describe "#log_in" do

    it "successfully logs in with valid authentication data" do
      expect {
        subject.log_in
      }.to change(subject, :logged_in?).from(false).to(true)
    end

    it "fails to log in and raises and exception with invalid authentication data" do
      scraper = Bankr::Scrapers::LaCaixa.new(:login => '33358924',
                                             :password => '3333') 
      expect {
        scraper.log_in
      }.to raise_error(Bankr::Scrapers::CouldNotLogInException)
      scraper.logged_in?.should be_false
    end

  end

  it { should respond_to(:main_account_balance) }

end
