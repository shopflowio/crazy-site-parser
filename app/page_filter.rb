require 'debugger'
class PageFilter
  require 'nokogiri'
  attr_accessor :doc, :path, :title, :meta_desc, :content

## initialization logic
  def initialize(options = {})
    unless options[:path] and options[:config]
      raise "This method requires a :path and :config"
    end
    @path    = options[:path]
    @config  = options[:config]
    @doc     = Nokogiri::HTML.parse(File.open @path)

    define_ng_selectors
  end

  def define_ng_selectors
    s = @config.selectors
    @title     = @doc.instance_eval { eval s[:title_selector] }
    @meta_desc = @doc.instance_eval { eval s[:meta_description_selector] }
    @content   = @doc.instance_eval { eval s[:content_selector] }
  end



## parsing logic
  def parse_page
    {}.tap do |data|
      data[:title]            = @title
      data[:meta_description] = @meta_desc
      data[:content]          = parse_content if @content
    end
  end


  def parse_content
    # evaluate each element selector
    # append the result to a string
    e_s = @config.element_selectors

    parsed_elements = "".tap do |data|
      @content.instance_eval do
        e_s.each do |selector|
          data << eval(selector)
        end
      end
    end
    seperate_elements(parsed_elements)
  end


  def seperate_elements(parsed_elements)
    # take a string of html and parse with Nokogiri
    # seperate each element and append it to an array
    # concat the elements with the seperator string
    elements = []
    e_t_s    = @config.elements_to_seperate
    s_s      = @config.seperator_string
    ng_doc = Nokogiri::HTML.parse(parsed_elements)

    e_t_s.each do |element|
      ng_doc.css(element).each { |e| elements << e.inner_html }
    end

    elements * s_s
  end





## output logic
#  def output_html(path)
#    data = parse_page
#    out_dir = File.dirname(path)
#    content = data[:content]
#
#    save_images(@content, out_dir)
#    content = tidy_for_output(content, out_dir) if content
#
#    File.open(path, 'w') do |file|
#      "".tap do |html|
#	html << "<html><head>"
#	html << "<title>#{data[:title]}</title>"
#	html << "<meta name='generator' content='UpTrending HTML scrape and tidy ruby script!'"
#	html << "<meta name='description' content='#{data[:meta_description]}'>"
#	html << "</head>"
#	html << "<body>#{content}</body>"
#	html << "</html>"
#	file.puts html
#      end
#    end
#    puts path
#  end

#  def save_images(content, root_path)
#    if content and content.at_css('img')
#      content.css('img').each do |img|
#        relative_path = img['src']
#        file_to_open  = File.dirname(@path) + '/' + relative_path
#        file_to_save  = root_path + '/' + relative_path
#
#        FileUtils.mkdir_p File.dirname(file_to_save)
#        begin
#	  FileUtils.copy_file(file_to_open, file_to_save, true)
#        rescue Errno::ENOENT
#        end
#      end
#    end
#  end
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
