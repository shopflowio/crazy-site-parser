class PageFilter
  require 'nokogiri'
  require 'fileutils'
  attr_accessor :doc, :page, :title, :meta_description, :content

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
 
  def make_paths_absolute(content, root_path)
    "".tap do |data|
      content_ng = Nokogiri::HTML.parse(content)
      content_ng.css('img').each do |img|
        img['src'] = root_path + '/' + img['src']
      end
      data << content_ng.inner_html
    end
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

  def output_html(path)
    data = parse_page
    out_dir = File.dirname(path)
    save_images(@content, out_dir)
    content_with_abs_paths = make_paths_absolute(data[:content], out_dir) if data[:content]

    File.open(path, 'w') do |file|
      begin
	"".tap do |html|
	  html << "<html><head>"
	  html << "<title>#{data[:title]}</title>"
	  html << "<meta name='generator' content='UpTrending HTML scrape and tidy ruby script!'"
	  html << "<meta name='description' content='#{data[:meta_description]}'>"
	  html << "</head>"
	  html << "<body>#{content_with_abs_paths}</body>"
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
