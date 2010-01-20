class Tendersync::Session
  attr_reader :agent
  def initialize(site, user, pass)
    @username = user
    @password = pass
    @agent = WWW::Mechanize.new { |a| a.auth(user, pass) }
    @site       = site
    @login_site = "#{site}/login"
  end
  
  def login
    return if @logged_in
    puts "logging in to #{@login_site} as #{@username}..."
    page = @agent.get(@login_site)
    f = page.form_with(:action => '/login') do | login_form |
      login_form['email']    = @username 
      login_form['password'] = @password 
    end
    result = f.submit
    if result.links.find { | l | l.href =~ /forgot_password/}
      raise Tendersync::Runner::Error, "login failed--bad credentials"
    end
    # TODO Check the result for a valid login.
    @logged_in = true
  end
  
  def get(url)
    login
    begin
      page = @agent.get(url)
    rescue WWW::Mechanize::ResponseCodeError => e
      raise Tendersync::Runner::Error, "Unable to get #{url}"
    end
    def page.links_like(r)
      result = []
      links.each { |l| result << l.href if l.href =~ r }
      result
    end
    page
  end
  # Get the URL's of documents in the given section.
  def documents(section)
    login
    index = get("#{@site}/faqs/#{section}")
    index.links_like(%r{faqs/#{section}/.+}).collect { |url|"#{@site}#{url}" }
  end
  def edit_page_for(doc_url)
    login
    get "#{@site}#{get(doc_url).links_like(%r{faqs/\d+/edit}).first}"
  end
  
  # Return a hash of section id to section name.
  def all_sections
    sections = {}
    get("#{@site}/dashboard/sections").links.each do | link |
      if link.href =~ %r{/dashboard/sections/(.*)/edit$}
        name = $1
        sections[name] = link.text
      end
    end
    sections    
  end

  def edit_form_for(section, edit_page)
    edit_page.forms.each do |form|
      document = Tendersync::Document.from_form(section,form)
      return document unless document.document_id.nil?
    end
  end
  def pull_from_tender(*sections)
    sections = all_sections.keys if sections.empty?
    for section in sections do 
      documents(section).collect do |doc_url|
        edit_page = edit_page_for(doc_url)
        doc = edit_form_for(section, edit_page)
        puts "   #{doc.permalink}"
        doc.save unless $dry_run
      end
    end
  end

  def get_section_id(section)
    page = get("#{@site}/dashboard/sections/#{section}")    
    form = page.form_with(:action => "/dashboard/sections/#{section}")    
    form.form_node.to_s =~ /id="edit_section_(.*?)"/
    $1    
  end
    
  # Print out a list of all documents
  def ls(*sections)
    sections = all_sections.keys if sections.empty?
    
    sections.each do | section |
      puts "Section #{section}"
      documents(section).map {|url| url =~ %r{/([^/]*)$}  && $1 }.each do |link|
        puts "   #{link}"
      end
    end
  end
  def post(document)
    login
    page = "#{@site}/faqs/#{document.section}/#{document.permalink}"
    form = edit_page_for(page).form_with(:action => /edit/)
    raise "Unable to load form for page: #{page}" unless form
    document.to_form(form)
    form.submit unless $dry_run
  end
  def create_document(section,permalink,body, title)
    login
    form = get("#{@site}/faq/new").form_with(:action => "/faqs")

    puts "Using default Title..." if title.nil?
    title = "New Tendersync::Document" if title.nil?
    document = Tendersync::Document.new(
            :section => section,
            :title => title,
            :permalink => permalink,
            :body => body
    )
    document.to_form(form)
    return if $dry_run
    
    id = get_section_id(section)
    
    form.radiobuttons_with(:value => id).first.click
    form.submit
    Tendersync::Document.from_form(section,edit_page_for("#{@site}/faqs/#{section}/#{permalink}").form_with(:action => /edit/))
  end
end
