$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'

require 'lib/bankr'

require 'rspec'
require 'rspec/autorun'

require 'yaml'

# Valid login data for a bank. Access to it using:
# VALID_DATA["login"]
# VALID_DATA["password"]
#
VALID_DATA = YAML.load( File.open('spec/support/valid_data.yml') )
