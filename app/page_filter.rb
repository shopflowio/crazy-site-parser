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
    c = Nokogiri::HTML::DocumentFragment.parse(c)                              # create Nokogiri doc
    @config.for_each_element.each do |e|                     # for each element to operate on...
      e.tap do |element, actions|

        # parse attribute if one, and generate xpath selector
	if /\([a-z]+\=.+\)/.match element
	  attribute  = /[a-z]+\=/.match(element)[0].chop
	  value      = /\=.+\)/.match(element)[0].chop.reverse.chop.reverse # crazy
	  actual_el  = /^[a-z]+\(/.match(element)[0].chop
	  xpath_code = "#{actual_el}[@#{attribute}='#{value}']"
	else
	  xpath_code = element
	end

        # now operate on each occurence of that element
	c.xpath(xpath_code).each do |el|
          el.instance_eval do

	    if actions['before_insert']
	      add_previous_sibling(actions['before_insert']) 
            end

            if actions['after_insert']
	      add_next_sibling(actions['after_insert'])
            end

            if actions['surround_with']
              add_previous_sibling(actions['surround_with'])
              add_next_sibling(actions['surround_with'])
            end

            if actions['convert_to']
              self.node_name = actions['convert_to']
            end

            if actions['remove_attributes']
              actions['remove_attributes'].each { |a| remove_attribute(a) }
            end

            if actions['remove_children']
              actions['remove_children'].each do |a|
                children = xpath(a)
                children.remove
              end
            end

            # find actions that match attribute names
            attributes = attribute_nodes.map { |node| node.name }
            attribute_actions = actions.keys.map { |key| key if attributes.include? key }.compact

            # evaluate those attribute actions
            attribute_actions.each do |action|
              # check for a variable, and evaluate it if it exists
              if /\$/.match actions[action]
                variable    = /\$#{action}/
                replacement = get_attribute(action)
                value       = eval( actions[action].gsub(variable, replacement) )
              else
                value       = eval( actions[action] )
              end

              set_attribute(action, value)
            end

            if actions['remove_if_empty']
              remove if self.content.empty?
            end
          end
        end
      end 
    end
    c = c.to_html
    c = condense_spaces(c)           if @config.condense_spaces
    c = strip_unwanted_characters(c) if @config.characters_to_strip
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

