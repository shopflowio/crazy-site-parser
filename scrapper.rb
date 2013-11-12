#rvm 1.8.7
class Scrapper

  require 'awesome_print'
  require 'fileutils'
  require 'sanitize'
  require 'tidy_ffi'

  def self.parse_page(page)
    doc = Nokogiri::HTML(File.open page)
    {}.tap do |data|
      data[:url]              = "http://www.delloro.com/#{page}"
      data[:title]            = doc.at_css('title').text if doc.at_css('title')
      data[:meta_description] = doc.at_css('meta[name="DESCRIPTION"]')['content'] if doc.at_css('meta[name="DESCRIPTION"]')
      data[:content]          = doc.at_css('table[width="622"]').inner_html if doc.at_css('table[width="622"]')
    end
  end

  def self.sanitize_html(html)
    Sanitize.clean(html, Sanitize::Config::RESTRICTED)
  end

  def self.tidy_html(html)
    TidyFFI::Tidy.with_options(
      :indent           => 'yes',
      :tidy_mark        => false,
      :char_encoding    => 'utf8',
      :doctype          => 'omit',
      :bare             => true,
      :clean            => true,
      :break_before_br  => true,
      :drop_empty_paras => true
      ).new(html).clean
  end

  def self.clean_html(html)
    tidy_html sanitize_html(html)
  end

end


Dir.chdir('www.broadviewproduct.com')
puts pages = Dir['**/*.htm*']

failed = []

pages.each do |page|
  new_path = "../scraped_site/#{page}"
  FileUtils.mkdir_p(File.dirname(new_path))
  File.open(new_path, 'w') do |output|
    begin
     puts page
      data = Scrapper.parse_page(page)
      "".tap do |html|
        html << "<html><head>"
        html << "<title>#{data[:title]}</title>"
        html << "<meta name='generator' content='UpTrending HTML scrape and tidy ruby script!'"
        html << "<meta name='description' content='#{data[:meta_description]}'>"
        html << "</head>"
        html << "<body>#{Scrapper.sanitize_html(data[:content])}</body>"
        html << "</html>"
        output.puts Scrapper.tidy_html(html)
      end
    rescue Encoding::CompatibilityError
      failed << page
    end
  end
end

puts "character encoding error on the following:"
failed.each {|page| puts page}
