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

    @pages.each do |page|
      filename = page[:filename]
      path = "#{dir}/#{filename}"
      page[:filter].output_html(path)
    end
  end

end
