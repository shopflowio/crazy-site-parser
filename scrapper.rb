#rvm 1.8.7
require 'rubygems'
require 'nokogiri'
require 'awesome_print'
require 'fileutils'
require 'sanitize'
require 'tidy_ffi'

def parse_page(page)
  doc = Nokogiri::HTML(File.open page)
  {}.tap do |data|
    data[:url]              = "http://www.delloro.com/#{page}"
    data[:title]            = doc.at_css('title').text if doc.at_css('title')
    data[:meta_description] = doc.at_css('meta[name="DESCRIPTION"]')['content'] if doc.at_css('meta[name="DESCRIPTION"]')
    data[:content]          = doc.at_css('.maincol').inner_html if doc.at_css('.maincol')
  end
end

def sanitize_html(html)
  Sanitize.clean(html, Sanitize::Config::RELAXED.merge(:remove_contents => true))
end

def tidy_html(html)
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

def clean_html(html)
  tidy_html sanitize_html(html)
end

Dir.chdir('www.broadviewproduct.com')
pages = Dir['**/*.htm*']

# pages.each do |page|
#   new_path = "../wp.delloro/#{page}"
#   FileUtils.mkdir_p(File.dirname(new_path))
#   File.open(new_path, 'w') do |output|
#     puts page
#     data = parse_page(page)
#     "".tap do |html|
#       html << "<html><head>"
#       html << "<title>#{data[:title]}</title>"
#       html << "<meta name='generator' content='UpTrending HTML scrape and tidy ruby script!'"
#       html << "<meta name='description' content='#{data[:meta_description]}'>"
#       html << "</head>"
#       html << "<body>#{sanitize_html(data[:content])}</body>"
#       html << "</html>"
#       output.puts tidy_html(html)
#     end
#   end
# end
