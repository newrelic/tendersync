require 'rubygems'
require 'optparse'
require 'tendersync/session'
require 'tendersync/document'
require 'mechanize'
require 'yaml'

class Tendersync::Runner
  class Error < StandardError; end
  
  def initialize argv
    @dry_run  = false
    @sections = []
    @groups = []
    settings['groups'] ||= []
    @parser = OptionParser.new do |op|
      op.banner += " command\n"
      op.on('-n',                                  "dry run" )       { @dry_run  = true }
      op.on('-s', '--section', '=SECTION', String, "section, specify multiple separately" ) { |s| @sections << s }
      op.on('-u', '--username','=EMAIL',   String, "* login e-mail" ) {|str| settings['username'] = str }
      op.on('-p', '--password','=PASS',    String, "* password" )     {|str| settings['password'] = str }
      op.on(      '--docurl',  '=URL',     String, "* tender site URL" ) { |dir| settings['docurl'] = dir }
      op.separator ""
      op.separator "Indexing Options:"
      op.on('-g', '--group',   '=TITLE;regex', String, "*map of regex to group title for TOC groups") do | g |
        pair = g.split(';')
        settings['groups'] << [pair.first, pair.last]
      end
      op.on('-d', '--depth',   '=DEPTH', String, "*Number of levels to descend into a document being indexed") { | g | settings['depth'] = g.to_i }
      
      
        %Q{
    * saved in .tendersync file for subsequent default
 
    Commands:

        pull [URL, URL...]   -- download documents from tender; specify a section, a page URL, or
                                nothing to download all documents
        index                -- create a master index of each section, writing to section/file; specify
                                the sections with -s options; you can organize the TOC into groups by
                                mapping document titles to groups via a regular expression with -g options
        ls                   -- list files in specified session
        post PATTERN         -- post the matching documents to tender
        irb                  -- drops you into IRB with a tender session & related classes (for hacking/
                                one-time tasks).  Programmers only.
        create PERMALINK     -- create a new tender document with the specified permalink in the section
                                specified by --section=... (must be only one.)

    }.split(/\n/).each {|line| op.separator line.chomp }
    end
    
    begin
      @command,*@args = *@parser.parse(argv)
    rescue OptionParser::InvalidOption => e
      raise Error, e.message
    end
    
    @username = settings['username']
    @password = settings['password']
    @dochome = settings['docurl'] && settings['docurl'] =~ /^(http.*?)\/?$/ && $1
    @root = settings['root']
    
    case
    when ! @username
      raise Error, "Please enter a username and password.  You only need to do this once."
    when ! @password
      raise Error, "Please enter a password.  You only need to do this once."
    when ! @dochome
      raise Error, "Please enter a --docurl indicating the home page URL of your Tender docs.\n" +
           "You only need to do this once."
    else
      settings.save!
    end
  end
  
  def run
    $session = Tendersync::Session.new @dochome, @username, @password
    $dry_run = @dry_run
    case @command || 'help'
    when 'help'
      raise Error, @parser.to_s
    when *%w[pull post create irb ls index]
      send @command
    else
      raise Error, "Unknown command: #{@command}\n\n#{@parser}"
    end
  end
  
  private
  
  def ls
    $session.ls *sections
  end
  
  def pull
    if @args.size > 0
      @args.each do |url|
        section = url =~ /\/faqs\/([^\/]*)\// && $1
        raise Error, "Invalid URI for document: #{url}" if section.nil?
        doc = Document.from_form(section, $session.edit_page_for(url).form_with(:action => /edit/))
        puts "   #{doc.permalink}"
        doc.save unless @dry_run
      end
    else
      sections.each do |section|
        puts "pulling #{section} docs ..."
        $session.pull_from_tender(section) unless @dry_run
      end
    end
  end
  
  def post
    documents = args.collect { |doc_name|
      matches =  if doc_name =~ %r{/}
        [doc_name]
      else
        Dir.glob("#{@root}/{#{sections.join(',')}}/#{doc_name}*")
      end
      if matches.empty?
        print "No documents match #{doc_name}\n"
      else
        matches.collect { |match| Document.read_from_file(match) }
      end
    }.flatten.compact
    documents.each { |document|
      if @dry_run
        print "post #{document.section}/#{document.permalink} to tender.\n"
      else
        $session.post(document)
      end
    }
  end
  
  def create
    raise Error, "You must specify exactly one section to put the document in." if sections.length != 1 
    raise Error, "You must specify exactly one document permalink."             if args.length != 1 
    section,permalink = sections.first,args.first
    filename = "#{@root}/#{section}/#{permalink}"
    if @dry_run
      puts "Create document #{permalink} in #{section} as #{filename}"
    else
      text = File.read(filename) rescue ""
      text = "Put Text Here" if text.strip.empty?
      document = $session.create_document(section,permalink,text)
      document.save
    end
  end
  
  def irb
    puts <<-EOF

      Use $session to access the Tendersync::Session instance.
      Use Tendersync::Document to manipulate documents local and remote.

      Examples of crazy stuff you could try:

          puts $session.all_sections.inspect

          $session.pull_from_tender('troubleshooting')  

          $session.post(Tendersync::Document.index('docs').save)

          Tendersync::Document.each { |d| puts d.body.split(/\W/).join("\\n") }

          doc = Tendersync::Document.read_from_file("./docs/agent-api")
          doc.body.gsub! /api/,"API"
          doc.save

    EOF
    ARGV.clear
    require 'irb'
    require 'irb/completion'
    $sections = sections
    IRB.start
  end
  def index
    groups = settings['groups'].map do |title,regex|
      regex = eval(regex) if regex =~ %r{^/.*/[a-z]*$}
      Tendersync::Document::Group.new title, Regexp.new(regex)
    end
    section_details = $session.all_sections
    sections.each do |section|
      doc = Tendersync::Document.index_for section, section_details[section]
      puts "indexing #{section}: #{doc.section}/#{doc.permalink}"
      doc.refresh_index groups, settings['depth'] || 2
      doc.save
    end
  end
  def sections
    @sections = $session.all_sections.keys if @sections.empty? 
    @sections
  end
  def settings
    case
    when @settings
      return @settings 
    when File.exists?(".tendersync")
      File.open(".tendersync", "r") { |f| @settings = YAML.load(f) }
    else
      @settings = {}
    end
    def @settings.save!
      File.open(".tendersync","w") do |f|
        f.write(self.to_yaml)
      end
    end
    @settings
  end
end