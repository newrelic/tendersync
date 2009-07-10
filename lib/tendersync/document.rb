require 'fileutils'
require 'set'

class Tendersync::Document < Hash
  #
  # Basically a bag of values, like an OpenStruct
  #
  Fields = %w[section document_id title permalink keywords body]
  
  NUM_DASHES = 28 # the number of dashes in keyword fields
  def method_missing(meth,*args)
    case 
      when args.empty? && has_key?(meth) && Fields.include?(meth.to_s)
      self[meth].chomp
      when args.length == 1 && meth.to_s =~ /^(.*)=$/ && Fields.include?($1)
      self[meth.to_s[0..-1].intern] = args.first
    else
      super
    end
  end
  
  def initialize(values)
    super.update(values)
  end
  #
  # Documents can be read from / written to a file
  #
  def to_s
    Fields.collect { |field| ("-"*NUM_DASHES)+" #{field} "+("-"*NUM_DASHES) +"\n#{self[field]}\n" }.join
  end
  def save
    FileUtils.mkdir_p section
    File.open("#{section}/#{permalink}",'w') { |f| f.print self }
    self
  end
  def self.load(section, io)
    values = { :section => section }
    key = data = nil
    while line = io.gets
      line.chomp!
      if line =~ /^-{#{NUM_DASHES}} (.+) -{#{NUM_DASHES}}$/
        values[key] = data.join("\n") if data 
        key = $1.intern
        data = []
        puts "found #{key}" 
      else
        raise "missing keyword line" unless data
        data << line
      end
    end
    values[key] = data.join("\n") if key
    new values
  end
  
  def self.read_from_file(file_name)
    section = file_name.split('/')[-2] 
    if !File.exists? file_name
      raise Tendersync::Runner::Error, "Cannot read #{file_name}"
    end
    File.open(file_name) { |f| self.load(section, f) }
  end
  
  #
  # Can be scraped from a form
  #
  def self.from_form(section,form)
    values = {
      :document_id => form.action[%r{/faqs/(\d+)/edit},1],
      :section => section
    }
    form.fields.each { |tf|
      if field_name = tf.name[/faq\[(.*)\]/,1]
        value = tf.value.map { |line| line.chomp }.join("\n")
        values[field_name.intern] = value
      end
    }
    new(values)
  end
  def to_form(form)
    form.fields.each { |tf|
      if field_name = tf.name[/faq\[(.*)\]/,1] and has_key? field_name.intern
        tf.value = self[field_name.intern].map {|line| line.chomp }.join("\r\n")
      end
    }
  end
  def self.each(section)
    Dir.glob("#{section}/*").each { |f| yield Tendersync::Document.read_from_file(f) }
  end
  
  def self.index_for(section_id, section_name)
    new(:section => section_id,
        :title => "#{section_name} Table of Contents",
        :permalink => "#{section_id}-table-of-contents",
        :keywords => "toc index")
  end
  def refresh_index
    toc = {}
    link_root = {}
    self.class.each(section) do |document|
      next if document.permalink =~ /-table-of-contents$/
      puts "  processing #{document.title}..."
      title,link = nil
      title = document.title
      link_root[title] = document.permalink
      document.body.scan(%r{<a name=(.*?)>|^(##+) *(.*?) *\r?\n?$}i) 
      # puts "    found #{$0}"
      name,level,text = $1,($2 ? $2.length : nil),$3
      if name
        link = eval(name)
        puts "    bad link: #{link.inspect} in #{title}" if link =~ / /
      elsif level == 1
        puts "    using level 1: #{title}:#{text}"
      else
        puts "    link recommended for #{title}:#{text}" if level == 2 and !link
        kind = case title
          when / page$/i:               :pages
          when /instal|config|custom/i: :install
        else                          :advanced
        end
        toc[kind] ||= {}
        toc[kind][title] ||= []
        toc[kind][title] << [text,link] if level == 2
        link = nil
      end
    end
    io = StringIO.new
    io.puts
    [:install,:pages,:advanced].each do |k| 
      next if toc[k].nil?
      case k
        when :install  : io.puts "## Installation and configuration"
        when :pages    : io.puts "## Page by page tour of RPM"
        when :advanced : io.puts "## Advanced topics"
      end
      toc[k].keys.sort.each do |s| 
        io.puts "### [#{(s+']').ljust(40)} (#{link_root[s]})"
        toc[k][s].each do |h| 
          io.puts "* [#{(h[0]+']').ljust(42)} (#{link_root[s]}##{h[1]})"
        end
        io.puts 
      end
    end
    if $dry_run
      puts io.string
    else
      self.body = io.string
    end
  end
end