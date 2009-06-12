class A_document < Hash
  #
  # Basically a bag of values, like an OpenStruct
  #
  Fields = [:document_id,:title,:permalink,:keywords,:body]
  def method_missing(meth,*args)
    if args.empty? and has_key? meth
      self[meth]
    elsif args.length == 1 and args.first =~ /=$/
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
    Fields.collect { |field| "------------------------- #{field} ----------------------------\n#{self[field]}\n" }.join
  end
  def save
    File.open("#{$root}/#{section}/#{permalink}",'w') { |f| f.print self }
    self
  end
  def self.read_from(file_name)
    values = {:section => file_name.split('/')[-2] }
    key,data = nil,''
    if !File.exists? file_name
      puts "Cannot read #{file_name}"
      abort
    end
    File.open(file_name) { |f|
      while line = f.gets
        if line.chomp =~ /^------------------------- (.+) ----------------------------$/
          values[key] = data if key
          key,data = $1.intern,''
        else
          data << line
        end
      end
      values[key] = data.chomp if key
    }
    new(values)
  end
  #
  # Can be scraped from filled into a form
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
  #
  # The class (w. $root/section) is a collection and can create an index
  #
  def self.each(section)
    Dir.glob("#{$root}/#{section}/*").each { |f| yield A_document.read_from(f) }
  end
  def self.index(section)
    raise "FixMe: Document ID & subheadings for index hardcoded for RPM documentation only." unless section == 'docs'
    toc = {}
    link_root = {}
    each(section) { |document|
      title,link = nil
      title = document.title
      link_root[title] = document.permalink
      document.body.scan(%r{<a name=(.*?)>|^(##+) *(.*?) *\r?\n?$}i) {
        name,level,text = $1,($2 ? $2.length : nil),$3
        if name
          link = eval(name)
          print "Bad link: #{link.inspect} in #{title}\n" if link =~ / /
        elsif level == 1
          print "Using level 1: #{title}:#{text}\n"
        else
          print "Link needed: #{title}:#{text}\n" if level == 2 and !link
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
      } unless document.permalink =~ /knowledge-base-table-of-contents/
    }
    toc_document = A_document.new(
                                  :section => section,
                                  :document_id => 1920,
                                  :title => "Knowledge Base Table of Contents",
                                  :permalink => "knowledge-base-table-of-contents",
                                  :keywords => "TOC TableOfContents",
                                  :body => "\n\n"+[:install,:pages,:advanced].collect { |k| [
                                                                                             case k
                                                                                             when :install  : "## Installation and configuration\n"
                                                                                             when :pages    : "## Page by page tour of RPM\n"
                                                                                             when :advanced : "## Advanced topics\n"
                                                                                             end,
                                                                                             toc[k].keys.sort.collect { |s| [
                                                                                                                             "### [#{(s+']').ljust(40)} (#{link_root[s]})",
                                                                                                                             toc[k][s].collect {|h| 
                                                                                                                               "* [#{(h[0]+']').ljust(42)} (#{link_root[s]}##{h[1]})"
                                                                                                                             },
                                                                                                                             ""
                                                                                                                            ]},
                                                                                             "",
                                                                                             "", 
                                                                                            ]}.flatten.join("\n")
                                  )
    toc_document
  end
end
