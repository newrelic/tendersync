require 'rubygems'
require 'echoe'
%w[rake rake/clean fileutils newgem rubigen].each { |f| require f }
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

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
Echoe.new(GEM_NAME, Tendersync::VERSION) do |p|
  p.author = AUTHOR
  p.email = EMAIL
  p.summary = SUMMARY
  p.url = HOMEPAGE
  p.project = 'newrelic'
  p.description = DESCRIPTION
  p.version = Tendersync::VERSION
  p.need_tar_gz = false
  p.need_gem = true
  p.bin_files = 'bin/tendersync'
  p.runtime_dependencies = [
     ['mechanize','>= 0.9.3'],
  ]
  p.development_dependencies = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  p.ignore_pattern = %w[docs/** general/** troubleshooting/**]
  p.clean_pattern |= %w[**/.DS_Store tmp *.log]
end

Dir['tasks/**/*.rake'].each { |t| load t }

