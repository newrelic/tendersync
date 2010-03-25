$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Tendersync
  autoload :Document, 'tendersync/document'
  autoload :Runner,   'tendersync/runner'
  autoload :Session,  'tendersync/session'

  VERSION = '1.0.10'
end
