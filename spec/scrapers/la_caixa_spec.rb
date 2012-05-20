require 'spec_helper'

describe Bankr::Scrapers::LaCaixa do

  subject { Bankr::Scrapers::LaCaixa.new(:login => VALID_DATA["login"], :password => VALID_DATA["password"])}

  it { should respond_to(:log_in) }

  describe "#log_in", :webmock => false do

    it "successfully logs in with valid authentication data" do
      WebMock.allow_net_connect!
      expect {
        subject.log_in
      }.to change(subject, :logged_in?).from(false).to(true)
      WebMock.disable_net_connect!
    end

    it "fails to log in and raises and exception with invalid authentication data" do
      WebMock.allow_net_connect!
      scraper = Bankr::Scrapers::LaCaixa.new(:login => '33358924',
                                             :password => '3333')
      expect {
        scraper.log_in
      }.to raise_error(Bankr::Scrapers::CouldNotLogInException)
      scraper.logged_in?.should be_false
      expect {
        scraper.landing_page
      }.to raise_error(Bankr::Scrapers::NotLoggedInException)
      WebMock.disable_net_connect!
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

  context "public getters without cache", webmock: true do

    it { should respond_to(:_accounts) }

    describe "#_accounts" do
      context "with only one account" do
        before do
          stub_request(:any, /.*/).to_return(:body => fixture(:la_caixa, :account_show), :headers => { 'Content-Type' => 'text/html' })
          
          agent = Mechanize.new
          landing_page = agent.get("http://www.bank.com/accounts/1/movements")

          agent.stub(:click).and_return(landing_page)
          subject.stub(:landing_page).and_return(landing_page)

          subject.stub(:agent).and_return(agent)
        end

        it "counts correctly the accounts number" do
          subject.should have(1)._accounts 
        end

        it "returns correctly the balance" do
          fetched_accounts = subject._accounts

          fetched_accounts[0].balance.should == 673.56
          fetched_accounts[0].name.should == 'Cuenta recibos'
        end
      end
      context "with more than one account" do
        before do
          # Mocking around
          stub_request(:any, /.*/).to_return(:body => fixture(:la_caixa, :account_list), :headers => { 'Content-Type' => 'text/html' })

          agent = Mechanize.new
          landing_page = agent.get('http://www.bank.com/accounts')

          agent.stub(:click).and_return(landing_page)
          subject.stub(:landing_page).and_return(landing_page)

          subject.stub(:agent).and_return(agent)
        end

        it "fetches the accounts all the accounts" do
          # Expectations
          subject.should have(2)._accounts
        end

        it "fetches the name and balance for each account" do
          fetched_accounts = subject._accounts

          fetched_accounts[0].name.should == 'Cuenta principal'
          fetched_accounts[0].balance.should == 2140.78

          fetched_accounts[1].name.should == 'Cuenta secundaria'
          fetched_accounts[1].balance.should == 0.00
        end
      end
    end

    describe "#_movements_for" do

      before(:each) do
          # Mocking around
          stub_request(:any, /accounts\/1$/).to_return(:body => fixture(:la_caixa, :account_show), :headers => { 'Content-Type' => 'text/html' })
          stub_request(:any, /movements$/).to_return(:body => fixture(:la_caixa, :account_movements), :headers => { 'Content-Type' => 'text/html' })
          stub_request(:any, /movements\/2$/).to_return(:body => fixture(:la_caixa, :account_movements_paginated), :headers => { 'Content-Type' => 'text/html' })

          account_show = subject.agent.get('http://www.bank.com/accounts/1')
          movement_list = subject.agent.get('http://www.bank.com/accounts/1/movements')
          movement_list2 = subject.agent.get('http://www.bank.com/accounts/1/movements/2')

          subject.agent.should_receive(:click).exactly(3).times.and_return(account_show, account_show, movement_list2)
          subject.agent.should_receive(:submit).exactly(1).times.and_return(movement_list)
          subject.stub(:landing_page).and_return(account_show)

          @account = mock('account', :is_a? => true, :name => 'Cuenta recibos')
      end

      context "by default" do
        it "fetches the movements for the given account from the current month" do
          movements = []

          Timecop.travel(Date.civil(2011,11,11)) do
            movements = subject._movements_for(@account)
          end

          movements.size.should == 16

          movements[0].amount.should == -10.86
          movements[0].statement.should == '8 ESTATE'
          movements[0].date.should == Date.civil(2011,11,11)

          movements[15].amount.should == 8000.00
          movements[15].statement.should == 'NOMINA'
          movements[15].date.should == Date.civil(2011,11,1)
        end
      end
    end
  end
end
