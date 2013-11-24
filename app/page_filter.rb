require 'debugger'
class PageFilter
  require 'nokogiri'
  attr_accessor :path, :root_path, :doc, :title, :meta_desc, :content

## initialization logic
  def initialize(options = {})
    required_options = [:path, :config]
    for option in required_options
      raise "#{option} required" unless options[option]
    end

    @path          = options[:path]
    @config        = options[:config]
    @doc           = Nokogiri::HTML.parse(File.open @path)

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
      data[:title]       = @title
      data[:meta_desc]   = @meta_desc
      data[:content]     = parse_content if @content
    end
  end


  def parse_content
    # evaluate each element selector
    # append the result to a string
    e_s = @config.element_selectors

    c = "".tap do |data|
      @content.instance_eval do
        e_s.each do |selector|
          data << eval(selector)
        end
      end
    end
    clean_content(c)
  end

  def clean_content(c)
    c = seperate_elements(c)
    c = c.encode(@config.encoding)
    c = condense_spaces(c)
    c = strip_unwanted_characters(c)
    c
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
      ng_doc.css(element).each { |e| elements << e.to_html }
    end

    elements * s_s
  end

  def condense_spaces(c)
    c.gsub!(/\ +/, ' ') if @config.condense_spaces
  end

  def strip_unwanted_characters(c)
    character_array = @config.characters_to_strip
    unless character_array.nil?
      character_blob = character_array * ''
      c.tr!(character_blob, '')
    end
    c
  end

  def images
    # This method parses images from the entire @content area, irrespective
    # of whatever elements are parsed in parse_content. So a user could
    # choose to parse no img tags at all and still work with the images
    # in the site. Choosing to parse img tags only then serves to embed
    # img tags in the parsed content, as opposed to saving images but not
    # automatically linking them in the content.
    return nil if @content.nil?

    if @content.is_a? String
      @content = Nokogiri::HTML.parse(@content)
    end

    [].tap do |images|
      @content.css('img').each do |img|
        images  << img['src']
      end
    end
  end

  def to_html
    data = parse_page
    "".tap do |html|
      html << "<html><head>"
      html << "<title>#{data[:title]}</title>"
      html << "<meta name='description' content='#{data[:meta_desc]}'>"
      html << "</head>"
      html << "<body>#{data[:content]}</body>"
      html << "</html>"
    end
  end

end

