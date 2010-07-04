require 'spec_helper'

describe Bankr::Scrapers::LaCaixa do

  subject { Bankr::Scrapers::LaCaixa.new(:login => VALID_DATA["login"], :password => VALID_DATA["password"])}

  it { should respond_to(:log_in) }

  describe "#log_in", :webmock => false do

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
      scraper.landing_page.should raise_error(Bankr::Scrapers::NotLoggedInException)
    end

  end

  context "public getters with cache", :webmock => true do

    it { should respond_to(:accounts) }

    describe "#accounts" do

      it "fetches the accounts and caches them" do
        # The first time returns 3 accounts, the second time only 2
        subject.stub(:_accounts).and_return([double("account1"),double("account2"),double("account3")],
                                            [double("account1"),double("account2")])
        subject.should have(3).accounts
        subject.should have(3).accounts, "#accounts is not caching the accounts"
      end

    end

  end

  context "public getters without cache", :webmock => true do

    it { should respond_to(:_accounts) }

    describe "#_accounts" do

      it "fetches the accounts with their name, url and balance" do
        # Mocking around
        stub_request(:any, /.*/).to_return(:body => fixture(:la_caixa, :account_list), :headers => { 'Content-Type' => 'text/html' })

        agent = Mechanize.new
        landing_page = agent.get('http://www.bank.com/accounts')

        agent.stub(:click).and_return(landing_page)
        subject.stub(:landing_page).and_return(landing_page)

        subject.stub(:agent).and_return(agent)

        # Expectations
        subject.should have(3)._accounts

        fetched_accounts = subject._accounts 

        fetched_accounts[0].name.should == 'Main account'
        fetched_accounts[0].balance.should == '+5.000,00'

        fetched_accounts[1].name.should == 'Personal account'
        fetched_accounts[1].balance.should == '+500,00'

        fetched_accounts[2].name.should == 'Main account taxes'
        fetched_accounts[2].balance.should == '+2.500,00'
      end

    end

  end

end
