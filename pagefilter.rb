class PageFilter
  require 'nokogiri'
  attr_accessor :doc, :page, :title, :meta_description, :content

  def initialize(page)
    @page = page
    @doc  = Nokogiri::HTML(File.open @page)
    define_ng_selectors
  end

  def define_ng_selectors
    @title            = @doc.at_css('title')
    @meta_description = @doc.at_css('meta[name="DESCRIPTION"]')
    @content          = @doc.at_css('table[width="622"]')
  end

  def parse_page
    {}.tap do |data|
      data[:url]              = "http://www.delloro.com/#{@page}"
      data[:title]            = @title.text if @title
      data[:meta_description] = @meta_description['content'] if @meta_description
      data[:content]          = parse_content(@content) if @content
    end
  end

  def parse_content(content)
    all_the_ps = content.css('p')
    "".tap do |data|
      all_the_ps.each do |p|
        data << p.inner_html
        data << '<br /><br />'
      end
    end
  end

  def output_html(path)
    data = parse_page
    File.open(path, 'w') do |file|
      begin
	"".tap do |html|
	  html << "<html><head>"
	  html << "<title>#{data[:title]}</title>"
	  html << "<meta name='generator' content='UpTrending HTML scrape and tidy ruby script!'"
	  html << "<meta name='description' content='#{data[:meta_description]}'>"
	  html << "</head>"
	  html << "<body>#{data[:content]}</body>"
	  html << "</html>"
	  file.puts html
	end
	puts path
      rescue Encoding::CompatibilityError
        return nil
      end
    end
  end

end
