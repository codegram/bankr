require 'bankr'
require 'rspec'

require 'webmock/rspec'
require 'timecop'
require 'active_support'
require 'active_support/time'

require 'yaml'

# Valid login data for a bank. Access to it using:
# VALID_DATA["login"]
# VALID_DATA["password"]
#
VALID_DATA = YAML.load( File.open('spec/support/valid_data.yml') )

module LaCaixaPaths
  def account_list
    "https://loc12.lacaixa.es/WAP/SPDServlet?WebLogicSession=m60SMv8JkFJXlylLJGNzR7j5nyXTrSzkzt2Cyy62yJm9rSFprbpj!-1050649781!1278180596824&id_params=2045199442"
  end
end

module HelperMethods
  def fixture(scraper,name)
    File.read(File.dirname(__FILE__) +  "/support/pages/#{scraper}/#{name}.html")
  end
end

RSpec.configuration.include(LaCaixaPaths)
RSpec.configuration.include(HelperMethods)
RSpec.configuration.include(WebMock::API, :webmock => true)
