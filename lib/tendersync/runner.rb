require 'optparse'
require 'tendersync/session'
require 'tendersync/document'

class Tendersync::Runner
  class Error < StandardError; end
  attr_reader :dry_run
  
  def initialize argv

    @dry_run  = false
    @sections = []
    @username, @password = File.open(".login","r") { |f| f.read.chomp.split(":") } if File.exists? ".login"
    
   
    settings = load_config_file

    option_parser = OptionParser.new do |op|
      op.banner += " command\n"
      op.on('-n',                                  "Dry run" )       {        @dry_run  = true }
      op.on('-r', '--root',    '=PATH',    String, "Document root" ) { |dirt| settings['root'] = dir }
      op.on('-s', '--sections','=SECTIONS',Array,  "Sections" )      { |list| @sections = list }
      op.on('-u', '--username','=EMAIL',   String, "Login e-mail (#{@username})" ) {|str| settings['username'] = str }
      op.on('-p', '--password','=PASS',    String,  "Login password" )  {|str| settings['password'] = str }
        %Q{
    Commands:

        pull [url, url...]   -- download documents from tender; specify a section, a page URL, or
                                nothing to download all documents
        index                -- index specified session (presently only works with --section=docs)
        post document-names  -- post the specified document to tender; names may include wild cards
        irb                  -- drops you into IRB with a tender session & related classes (for hacking/
                                one-time tasks).  Programmers only.
        create permalink     -- create a new tender document with the specified permalink in the section
                                specified by --section=... (must be only one.)

    }.split(/\n/).each {|line| op.separator line.chomp }
    end
    
    @username = settings['username']
    @password = settings['password']
    @dochome = settings['dochome']
    @root = settings['root']
    
    @command,*@args = *option_parser.parse(argv)
    
    if @username.nil? || @password.nil? || @username.empty? || @password.empty?
      raise Error, "Please enter a username and password.  You only need to do this once."
    else
      save_config_file
    end
  end
  
  def run
    @session = Session.new
    case @command || 'help'
      when 'help'
      raise Error, option_parser.to_s
      when 'pull', 'post', 'create', 'irb', 'ls'
      send @command
    else
      raise Error, option_parser.to_s
    end
  end
  
  private

  def ls
    @sections.each do |section|
      puts ">> #{section}"
      @session.ls section
    end
  end
  
  def pull
    if @args.size > 0
      @args.each do |url|
        section = url =~ /\/faqs\/([^\/]*)\// && $1
        raise Error, "Invalid URI for document: #{url}" if section.nil?
        doc = Document.from_form(section, @session.edit_page_for(url).form_with(:action => /edit/))
        puts "   #{doc.permalink}"
        doc.save unless @dry_run
      end
    else
      @sections.each do |section|
        puts "pulling #{section} docs ..."
        @session.pull_from_tender(section) unless @dry_run
      end
    end
  end
  
  def post
    documents = args.collect { |doc_name|
      matches =  if doc_name =~ %r{/}
        [doc_name]
      else
        Dir.glob("#{@root}/{#{@sections.join(',')}}/#{doc_name}*")
      end
      if matches.empty?
        print "No documents match #{doc_name}\n"
      else
        matches.collect { |match| Document.read_from(match) }
      end
    }.flatten.compact
    documents.each { |document|
      if @dry_run
        print "post #{document.section}/#{document.permalink} to tender.\n"
      else
        @session.post(document)
      end
    }
  end
  
  def create
    raise Error, "You must specify exactly one section to put the document in." if @sections.length != 1 
    raise Error, "You must specify exactly one document permalink."             if args.length != 1 
    section,permalink = @sections.first,args.first
    filename = "#{@root}/#{section}/#{permalink}"
    if @dry_run
      puts "Create document #{permalink} in #{section} as #{filename}"
    else
      text = File.read(filename) rescue ""
      text = "Put Text Here" if text.strip.empty?
      document = @session.create_document(section,permalink,text)
      document.save
    end
  end
  
  def irb
    puts <<EOF

      Interesting classes: [Document,Session]
      Interesting globals: [@root, @sections, @session]

      Examples of crazy stuff you could try:

          @session.pull_from_tender('troubleshooting')

          `git commit -a -m "Automatic synchronization with tender"`
          `git push`

          @session.post(Document.index('docs').save)

          Document.each { |d| print d.body.split(/\W/).join("\\n") }

          doc = Document.read_from("\#{@root}/docs/agent-api")
          doc.body.gsub! /api/,"API"
          doc.save

EOF
    ARGV.clear
    require 'irb'
    require 'irb/completion'
    IRB.start
  end
  def index
    #      if @sections != %w{ docs }
    #        raise Error, "Only the doc section can be indexed at present."
    if @dry_run
      # FIXME I think we should build the sections, and not post
      puts "build index for #{@sections} and post to tender"
    else
      @args.each do |section|
        puts "indexing #{section} and posting to tender..."
        @session.post(Document.index(section).save)
      end
    end
  end
  def load_config_file
    if File.exists? ".login"
      File.open(".tendersync", "r") { |f| settings = YAML.load(f) }
    else
      {}
    end
  end
  def save_config_file
    File.open(".tendersync","w") do |f|
      f.write(settings.to_yaml)
    end
  end
end
