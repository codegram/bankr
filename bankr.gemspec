$:.push File.expand_path("../lib", __FILE__)
require "bankr/version"

Gem::Specification.new do |s|
  s.name = %q{bankr}
  s.version = Bankr::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Oriol Gual", "Josep M. Bach", "Josep Jaume Rey"]
  s.email = %q{info@codegram.com}
  s.homepage = %q{http://github.com/codegram/bankr}
  s.summary = %q{A gem to retrieve your bank account movements.}
  s.description = %q{A gem to retrieve your bank account movements.}
  s.rubyforge_project = 'bankr'

  s.add_runtime_dependency 'poltergeist', '~> 1.7.0'
  s.add_runtime_dependency 'capybara', '~> 2.4.4'
  s.add_runtime_dependency 'nokogiri', '~> 1.6.6'
  s.add_runtime_dependency 'activesupport', '~> 4'
  s.add_development_dependency "launchy"
  s.add_development_dependency "rspec", "~> 2.5.0"
  s.add_development_dependency "webmock", '~> 1.21.0'
  s.add_development_dependency "timecop", '~> 0.7.3'
  s.add_development_dependency "rake"
  s.add_development_dependency "pry"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
