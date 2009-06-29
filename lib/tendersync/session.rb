
class Tendersync::Session
  attr_reader :agent
  def initialize(site, user, pass)
    @username = user
    @password = pass
    @agent = WWW::Mechanize.new { |a| }
    @site       = site
    @login_site = "#{site}/login"
  end
  
  def login
    return if @logged_in
    puts "logging in as #{@username}..."
    page = @agent.get(@login_site)
    f = page.form_with(:action => '/login') do | login_form |
      login_form['email']    = @username 
      login_form['password'] = @password 
    end
    result = f.submit
    # TODO Check the result for a valid login.
    @logged_in = true
  end
  
  def get(url)
    login
    page = @agent.get(url)
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
    get("#{@site}/faqs/#{section}").links_like(%r{faqs/#{section}/.+}).collect { |url|"#{@site}#{url}" }
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
  
  def pull_from_tender(*sections)
    sections = all_sections.keys if sections.empty?
    for section in sections do 
      documents(section).collect do |doc_url|
        doc = Tendersync::Document.from_form(section,edit_page_for(doc_url).form_with(:action => /edit/))
        puts "   #{doc.permalink}"
        doc.save
      end
    end
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
    form = edit_page_for("#{@site}/faqs/#{document.section}/#{document.permalink}").form_with(:action => /edit/)
    document.to_form(form)
    form.submit
  end
  def create_document(section,permalink,body)
    login
    form = get("#{@site}/faq/new").form_with(:action => "/faqs")
    document = Tendersync::Document.new(
            :section => section,
            :title => "New Tendersync::Document",
            :permalink => permalink,
            :body => body
    )
    document.to_form(form)
    form.radiobuttons_with(:value => Tender_id_for_section[section]).first.click
    form.submit
    Tendersync::Document.from_form(section,edit_page_for("#{@site}/faqs/#{section}/#{permalink}").form_with(:action => /edit/))
  end
end
