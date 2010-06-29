require 'spec_helper'

describe Bankr::Scrapers::LaCaixa do

  subject { Bankr::Scrapers::LaCaixa.new(:login => '65148900', :password => '1234')}

  it { should respond_to(:log_in) }

  context "login" do

    it "logs in" do

      expect {
        subject.log_in
      }.to change(subject, :logged_in?).from(false).to(true)

       

    end

  end

end
