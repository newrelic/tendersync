require 'rubygems'
require 'echoe'
%w[rake rake/clean fileutils newgem rubigen].each { |f| require f }
require File.dirname(__FILE__) + '/lib/tendersync'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
Echoe.new('tendersync', Tendersync::VERSION) do |p|
  p.author = 'Bill Kayser'
  p.email = 'bkayser@newrelic.com'
  p.summary = "Utility for syncing and indexing files from ENTP's Tender site."
  p.url = 'http://www.newrelic.com'
  p.description = <<EOF
tendersync is a utility for syncing files from ENTP's Tender site for managing customer facing documentation.
It can be used to pull and push documents to a local repository as well as create indexes for each
documentation section.
EOF
  p.version = Tendersync::VERSION
  p.runtime_dependencies = [
     ['mechanize','>= 0.9.3'],
  ]
  p.development_dependencies = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  
  p.clean_pattern |= %w[**/.DS_Store tmp *.log]
end

Dir['tasks/**/*.rake'].each { |t| load t }

