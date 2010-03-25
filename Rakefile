require 'rubygems'
require 'rake'
# See http://www.rubygems.org/read/chapter/20 

require File.dirname(__FILE__) + '/lib/tendersync'

GEM_NAME = "tendersync"
GEM_VERSION = Tendersync::VERSION
AUTHOR = "Bill Kayser"
EMAIL = "bkayser@newrelic.com"
HOMEPAGE = "http://www.github.com/newrelic/tendersync"
SUMMARY = "Utility for syncing and indexing files from ENTP's Tender site."
DESCRIPTION = <<-EOF
Tendersync is a utility for syncing files from ENTP's Tender site for managing customer facing documentation.  It can be used to pull and push documents to a local repository as well as create indexes for each documentation section.
  EOF

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "tendersync"
    gem.summary = SUMMARY
    gem.description = DESCRIPTION
    gem.email = EMAIL
    gem.homepage = HOMEPAGE
    gem.author = AUTHOR
    gem.add_dependency 'mechanize', '>= 0.9.3'
    gem.version = GEM_VERSION
    gem.files = FileList['README*', 'lib/**/*.rb', 'History.txt', 'bin/*', 'spec/**/*', '**/*.rake', 'script/*'].to_a
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Tendersync version #{GEM_VERSION}"
  rdoc.rdoc_files.include('History.txt')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Dir['tasks/**/*.rake'].each { |t| load t }
