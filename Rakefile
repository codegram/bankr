require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "bankr"
    gem.summary = %Q{A gem to retrieve your bank account information}
    gem.description = %Q{A gem to retrieve your bank account information}
    gem.email = "info@codegram.com"
    gem.homepage = "http://github.com/codegram/bankr"
    gem.authors = ["Oriol Gual", "Josep Mª Bach", "Josep Jaume Rey"]

    gem.add_dependency 'celerity'
    gem.add_development_dependency "rspec", ">= 2.0.0.beta.14"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

# Rake RSpec2 task stuff
gem 'rspec', '>= 2.0.0.beta.12'
gem 'rspec-expectations'

require 'rspec/core/rake_task'

desc "Run the specs under spec"
RSpec::Core::RakeTask.new do |t|

end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "bankr #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
