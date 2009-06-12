class A_tender_session
    def initialize
        @agent = WWW::Mechanize.new { |a| }
        @site       = 'http://support.newrelic.com'
        @login_site = 'http://rpm.newrelic.com'
        end
    def login
        return if @logged_in
        @agent.
          get("#{@login_site}/session/new").
          form_with(:action => '/session') { |login_form|
              login_form['email']    = $username 
              login_form['password'] = $password 
            }.
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
    def faq(section)
        get("#{@site}/faqs/#{section}").links_like(%r{faqs/#{section}/.+}).collect { |url|"#{@site}#{url}" }
        end
    def edit_page_for(doc_url)
        get "#{@site}#{get(doc_url).links_like(%r{faqs/\d+/edit}).first}"
        end
    def pull_from_tender(section)
        login
        faq(section).collect { |doc_url|
          doc = A_document.from_form(section,edit_page_for(doc_url).form_with(:action => /edit/))
          print "   #{doc.permalink}\n"
          doc.save
          }
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
        document = A_document.new(
            :section => section,
            :title => "New Document",
            :permalink => permalink,
            :body => body
           )
        document.to_form(form)
        form.radiobuttons_with(:value => Tender_id_for_section[section]).first.click
        form.submit
        A_document.from_form(section,edit_page_for("#{@site}/faqs/#{section}/#{permalink}").form_with(:action => /edit/))
        end
    end
