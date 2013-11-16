class PageFilter
  require 'nokogiri'
  attr_accessor :doc, :path, :title, :meta_description, :content

## initialization logic
  def initialize(options = {})
    unless options[:path] and options[:config]
      raise "This method requires a :path and :config\n
             path:   #{options[:path]}\n
             config: #{options[:config]}"
    end
    @path   = options[:path]
    @config = options[:config]
    @doc  = Nokogiri::HTML(File.open @path)
    define_ng_selectors
  end

  def define_ng_selectors
    @doc.tap do
      @title            = eval @config.title_selector
      @meta_description = eval @config.meta_description_selector
      @content          = eval @config.content_selector
    end
  end
#####

## parsing logic
  def parse_page
    {}.tap do |data|
      data[:url]              = "http://www.delloro.com/#{File.basename(@path)}"
      data[:title]            = @title.text if @title
      data[:meta_description] = @meta_description['content'] if @meta_description
      data[:content]          = parse_content if @content
    end
  end

#  def parse_content
#    data = ''
#    @content.tap do
#      for es in @config.element_selectors
#        data << eval es.inner_html # this is actually wrong. needs fix
#        data << @config.seperater_string
#      end
#    end
#  end





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
    html = html.encode('Windows-1252') # with utf-8 we get Â's
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
    html.tr!("\n", '')
    html.gsub!(/\ +/, ' ')
  end

end
