require 'rubygems'
require 'echoe'
%w[rake rake/clean fileutils newgem rubigen].each { |f| require f }
require File.dirname(__FILE__) + '/lib/tendersync'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
Echoe.new('tendersync', Tendersync::VERSION) do |p|
  p.author = 'Bill Kayser'
  p.email = 'bkayser@newrelic.com'
  p.summary = "Utility for syncing files from ENTP's Tender site"
  p.url = 'http://www.newrelic.com'
  p.description = <<EOF
Tendersync is a utility...
EOF
  p.version = Tendersync::VERSION
  p.runtime_dependencies = [
     ['mechanize','>= 0.9.3'],
  ]
  #p.rubyforge_name       = p.name # TODO this is default value
  #p.extra_deps         = [
  #   ['activesupport','>= 2.0.2'],
  # ]
  p.development_dependencies = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  
  p.clean_pattern |= %w[**/.DS_Store tmp *.log]
end

Dir['tasks/**/*.rake'].each { |t| load t }

