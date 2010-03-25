begin
  require 'spec'
  require 'mechanize'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'spec'
  gem 'mechanize'
  require 'mechanize'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'tendersync'

Spec::Runner.configure do |config|

  config.mock_with :mocha

end

