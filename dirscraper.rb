#rvm 1.8.7
class DirectoryScraper

  require './pagefilter'
  require 'fileutils'
  attr_accessor :dir, :page_paths, :pages

  def initialize(dir)
    raise "invalid directory" unless Dir.exists? dir
    @dir        = File.realdirpath dir
    @page_paths = Dir["#{@dir}/**/*.htm*"]
    @pages      = get_page_filters
  end

  def get_page_filters
    [].tap do |data|
      @page_paths.each do |path|
        data << { filename:   File.basename(path), 
                  filter:     PageFilter.new(path) }
      end
    end
  end

  def build_site_from_content(dir)
    FileUtils.remove_dir(dir, force: true) if Dir.exists? dir
    dir = File.realdirpath dir
    FileUtils.mkdir_p dir
    failed = []

    @pages.each do |page|
      filename = page[:filename]
      path = "#{dir}/#{filename}"
      result = page[:filter].output_html(path)
      if result == failed
        failed << filename
      else
        puts result
      end
      unless failed.empty?
        puts "character encoding error on the following:"
        failed.each { |failure| puts failure }
      end
    end
  end

end
