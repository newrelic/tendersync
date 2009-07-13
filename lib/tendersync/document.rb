require 'fileutils'
require 'set'

class Tendersync::Document
  Properties = [:section, :document_id, :title, :permalink, :keywords, :body]
  attr_accessor *Properties
  
  NUM_DASHES = 28 # the number of dashes in keyword fields
  
  class Group
    attr_reader :name, :title_regex
    def initialize(name, title_regex=//)
      @name, @title_regex = name, title_regex
    end
    Default = Group.new('Other') 
  end
  
  def initialize(values={})
    values.each do | prop, value |
      self.send "#{prop}=", value
    end
  end
  #
  # Documents can be read from / written to a file
  #
  def to_s
    io = StringIO.new
    Properties.each do |field|
      next unless value = self.send(field) 
      io.write  "-" * NUM_DASHES
      io.write " #{field} "
      io.write "-" * NUM_DASHES
      io.puts
      io.puts value
    end
    io.string
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
      if line =~ /^----+ (.+) -----+$/
        values[key] = data.join("\n") if data 
        key = $1.intern
        data = []
      else
        raise "keyword line not recognized: #{line}" unless data
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
        tf.value = self.send(field_name.intern).each_line {|line| line.chomp }.join("\r\n")
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
  
  # Update this document body with an index of all the documents in
  # this section.  Underneath the TOC entry for a document will be sub
  # entries for each named A element.
  #  
  # group_map is an associative array of /regex/ to "Title String" of
  # a group of documents.  It is used to divide up documents into
  # groups within the table of contents.  A document is placed in a
  # TOC group based on the first regex it matches in the group map.
  #
  # If group_map is empty then headings will be sorted alphabetically
  # and not grouped.
  def refresh_index(group_map=[])
    toc = {}
    link_root = {}
    self.class.each(section) do |document|
      next if document.permalink =~ /-table-of-contents$/
      puts "processing #{document.permalink}..."
      title,link = nil
      title = document.title
      link_root[title] = document.permalink
      document.body.scan(%r{<a name=(.*?)>|^(##+) *(.*?)\s*$}i) do
        heading_level = $2 && $2.length
        name = $1
        text = $3
        if name
          link = eval(name)
          puts "    bad link: #{link.inspect} in #{title}" if link =~ / /
        elsif heading_level == 1
          puts "  using level 1: #{title}:#{text}"
        else
          puts "  link recommended for #{title}:#{text}" if heading_level == 2 and !link
          group_pair = group_map.detect { | regex, t | title =~ regex } 
          group_title = (group_pair && group_pair.last) || 'Other'
          toc[group_title] ||= {}
          toc[group_title][title] ||= []
          toc[group_title][title] << [text,link] if heading_level == 2
          link = nil
        end
      end
    end
    io = StringIO.new
    io.puts
     (group_map << [ //, 'Other']).map do |regex, title |
      puts "  #{title} section..."
      next if toc[title].nil?
      puts "     ...processing"
      # Show the group heading unless there is only one group
      io.puts "## #{title}" unless group_map.size == 1
      toc[title].keys.sort.each do |s| 
        io.puts "### [#{(s+']')}(#{link_root[s]})"
        toc[title][s].each do |h| 
          io.puts "* [#{(h[0]+']')}(#{link_root[s]}##{h[1]})"
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
