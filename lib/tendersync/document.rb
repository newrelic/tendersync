require 'fileutils'
require 'set'
require 'yaml'

class Tendersync::Document
  Properties = [:section, :document_id, :title, :permalink, :keywords, :body]
  attr_accessor *Properties
  
  NUM_DASHES = 28 # the number of dashes in keyword fields
  
  class TOCEntry
    attr_reader :name, :link, :level
    attr_accessor :parent
    def initialize name, link=nil, level=nil
      @name = name
      @link = link if link
      @level = level if level
    end
    def children
      @children ||= []
    end
    # Write this element and all children, recursively as bullet lists with links
    def write_entries(io, depth=1, indent = 0, doc_link = parent.link)
      io.write " " * 4 * indent # indentation
      io.write "* " # bullet
      if link
        io.puts "[#{name}](#{doc_link}##{self.link})"
      else
        io.puts name
      end
      children.each { | child | child.write_entries(io, depth-1, indent+1, doc_link)} unless depth == 1
    end
    def add child
      if !parent || child.level > self.level
        children << child
        child.parent = self
      else
        parent.add(child)
      end
      child
    end
  end
  
  class Group < TOCEntry
    attr_reader :title_regex
    def initialize(name, title_regex=//)
      super(name, nil, nil)
      @title_regex = title_regex
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
      if field_name = tf.name[/faq\[(.*)\]/,1] and self.send(field_name.intern)
        lines = []
        self.send(field_name.intern).each_line {|line| lines << line.chomp }
        tf.value = lines.join("\r\n")
      end
    }
  end
  
  def self.each(section)
    Dir.glob("#{section}/*").each { |f| yield Tendersync::Document.read_from_file(f) }
  end
  
  def self.index_for(section_id, section_name, permalink = nil)
    permalink ||= "#{section_id}-table-of-contents"
    new(:section => section_id,
        :title => "#{section_name} Table of Contents",
        :permalink => permalink,
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
  #
  # depth s the number of nested levels to descend into a document.
  def refresh_index(groups=[], depth=2)
    generate_index(create_toc(groups), depth)  
  end
  
  private
  
  def create_toc(groups)
    groups << Group::Default # array of groups
    link_root = {}
    self.class.each(section) do |document|
      next if document.permalink =~ /-table-of-contents$/
      puts "indexing #{document.permalink}..."
      title = document.title
      group = groups.detect { | g | title =~ g.title_regex }
      doc_entry = TOCEntry.new title, document.permalink, 0
      group.add doc_entry
      last = doc_entry
      link = nil
      document.body.scan(%r{<a name=(.*?)>|^(#+)\s*(.*?)\s*$}i) do
        name = $1
        heading_level = $2 && $2.length
        text = $3
        if name
          # Record the link name for the next header
          link = eval(name)
        elsif heading_level == 1
          last = last.add(TOCEntry.new(text, link, heading_level)) 
        elsif heading_level >= 2  # level 2
          last = last.add(TOCEntry.new(text, link, heading_level)) 
          link = nil
        end
      end
    end
    groups
  end
  
  def generate_index(groups, depth)
    groups.reject! { | group | group.children.empty? }
    # Now go through each group
    io = StringIO.new
    io.puts
    groups.each do | group |
      # Show the group heading unless there is only one group
      io.puts "## #{group.name}" unless groups.size == 1
      group.children.each do | doc_entry |
        doc_link = doc_entry.link
        io.puts "### [#{doc_entry.name}](#{doc_link})"
        doc_entry.children.each do | doc_section |
          doc_section.write_entries(io, depth)
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

