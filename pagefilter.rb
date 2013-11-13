class PageFilter
  require 'nokogiri'
  require 'fileutils'
  attr_accessor :doc, :page, :title, :meta_description, :content

## initialization logic
  def initialize(path)
    @path = path 
    @doc  = Nokogiri::HTML(File.open @path)
    define_ng_selectors
  end

  def define_ng_selectors
    @title            = @doc.at_css('title')
    @meta_description = @doc.at_css('meta[name="DESCRIPTION"]')
    @content          = @doc.at_css('table[width="622"]')
  end
#####

## parsing logic
  def parse_page
    {}.tap do |data|
      data[:url]              = "http://www.delloro.com/#{File.basename(@path)}"
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
#####
 
## output logic
  def output_html(path)
    data = parse_page
    out_dir = File.dirname(path)
    content = data[:content]

    save_images(@content, out_dir)
    content = tidy_for_output(content, out_dir) if content

    File.open(path, 'w') do |file|
      "".tap do |html|
	html << "<html><head>"
	html << "<title>#{data[:title]}</title>"
	html << "<meta name='generator' content='UpTrending HTML scrape and tidy ruby script!'"
	html << "<meta name='description' content='#{data[:meta_description]}'>"
	html << "</head>"
	html << "<body>#{content}</body>"
	html << "</html>"
	file.puts html
      end
    end
    puts path
  end

  def save_images(content, root_path)
    if content and content.at_css('img')
      content.css('img').each do |img|
        relative_path = img['src']
        file_to_open  = File.dirname(@path) + '/' + relative_path
        file_to_save  = root_path + '/' + relative_path

        FileUtils.mkdir_p File.dirname(file_to_save)
        begin
	  FileUtils.copy_file(file_to_open, file_to_save, true)
        rescue Errno::ENOENT
        end
      end
    end
  end
#####

## tidy for output logic
  def tidy_for_output(html, root_path)
    html = make_paths_absolute(html, root_path)
    html = strip_unwanted_characters(html)
    html
  end

  def make_paths_absolute(html, root_path)
    "".tap do |data|
      content_ng = Nokogiri::HTML.parse(html)
      content_ng.css('img').each do |img|
        img['src'] = root_path + '/' + img['src']
      end
      data << content_ng.inner_html
    end
  end

  def strip_unwanted_characters(html)
    html = html.encode('Windows-1252') # with utf-8 we get Â's
    html.tr!("\n", '')
    html.gsub!(/\ +/, ' ')
  end

end
