require 'spec_helper'

describe Bankr::Scrapers::LaCaixa do

  subject { Bankr::Scrapers::LaCaixa.new(:login => VALID_DATA["login"], :password => VALID_DATA["password"])}

  it { should respond_to(:log_in) }

  describe "#log_in", :webmock => false do

    it "successfully logs in with valid authentication data" do
      pending "Won't pass until Webmock.allow_net_connect! works properly"
      expect {
        subject.log_in
      }.to change(subject, :logged_in?).from(false).to(true)
    end

    it "fails to log in and raises and exception with invalid authentication data" do
      pending "Won't pass until Webmock.allow_net_connect! works properly"
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

    describe "#_movements_for" do

      before(:each) do
          # Mocking around
          stub_request(:any, /movements$/).to_return(:body => fixture(:la_caixa, :account_movements), :headers => { 'Content-Type' => 'text/html' })
          stub_request(:any, /movements\/2$/).to_return(:body => fixture(:la_caixa, :account_movements_paginated), :headers => { 'Content-Type' => 'text/html' })

          agent = Mechanize.new
          landing_page = agent.get('http://www.bank.com/accounts/1/movements')

          agent.stub(:click).and_return(landing_page)
          subject.stub(:landing_page).and_return(landing_page)

          subject.stub(:agent).and_return(agent)

          @account = mock('account', :is_a? => true, :name => 'Main account')
      end

      context "by default" do

        it "fetches the movements for the given account from the last two weeks" do

          movements = []

          Timecop.travel(Date.parse('06/27/2010')) do
            movements = subject._movements_for(@account)
          end

          movements.size.should == 4

          movements[0].amount.should == '-13,50'
          movements[0].statement.should == 'AMC PARC VALLES'
          movements[0].date.should == Date.parse('06/25/2010')

          movements[3].amount.should == '+60,00'
          movements[3].statement.should == 'TRASPASO L.ABIERTA'
          movements[3].date.should == Date.parse('06/14/2010')

        end

      end

      context "when specifying :last => 1.week" do

        it "fetches the movements only from the last week" do

          movements = []

          Timecop.travel(Date.parse('06/27/2010')) do
            movements = subject._movements_for(@account, :last => 1.week)
          end

          movements.size.should == 1

          movements[0].amount.should == '-13,50'
          movements[0].statement.should == 'AMC PARC VALLES'
          movements[0].date.should == Date.parse('06/25/2010')

        end

      end

      context "with pagination" do

        it "fetches the corresponding movements navigating through pagination" do

          landing_page = subject.agent.get('http://www.bank.com/accounts/1/movements')
          second_page = subject.agent.get('http://www.bank.com/accounts/1/movements/2')

          subject.agent.should_receive(:click).exactly(3).times.and_return(landing_page, landing_page, second_page)
          subject.stub(:landing_page).and_return(landing_page)

          movements = []

          Timecop.travel(Date.parse('06/27/2010')) do
            movements = subject._movements_for(@account, :last => 1.month)
          end

          movements.size.should == 12

          movements[0].amount.should == '-13,50'
          movements[0].statement.should == 'AMC PARC VALLES'
          movements[0].date.should == Date.parse('06/25/2010')

          movements[11].amount.should == '-25,00'
          movements[11].statement.should == 'VODAFONE'
          movements[11].date.should == Date.parse('05/29/2010')
        end

      end

    end

  end

end
