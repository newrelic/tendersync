
class Tendersync::Session
  def initialize(site)
    @agent = WWW::Mechanize.new { |a| }
    @site       = site
    @login_site = "#{site}/login"
  end
  def login
    return if @logged_in
    @agent.get(@login_site)
    form_with(:action => '/login') { |login_form|
      login_form['email']    = $username 
      login_form['password'] = $password 
    }
    click_button
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
    get("#{@site}/faqs/#{section}").links_like(%r{faqs/#{section}/.+}).collect { |url|"#{@site}#{url}" }
  end
  def edit_page_for(doc_url)
    get "#{@site}#{get(doc_url).links_like(%r{faqs/\d+/edit}).first}"
  end
  def all_sections
    get "#{@site}/dashboard/sections"
  end
  def pull_from_tender(section)
    login
    faq(section).collect { |doc_url|
      doc = Document.from_form(section,edit_page_for(doc_url).form_with(:action => /edit/))
      puts "   #{doc.permalink}"
      doc.save
    }
  end
  def ls(section)
    login
    faq(section).collect do |doc_url|
      doc = Document.from_form(section,edit_page_for(doc_url).form_with(:action => /edit/))
      puts "  #{doc.title} (#{doc_url})"
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
    document = Document.new(
            :section => section,
            :title => "New Document",
            :permalink => permalink,
            :body => body
    )
    document.to_form(form)
    form.radiobuttons_with(:value => Tender_id_for_section[section]).first.click
    form.submit
    Document.from_form(section,edit_page_for("#{@site}/faqs/#{section}/#{permalink}").form_with(:action => /edit/))
  end
end
