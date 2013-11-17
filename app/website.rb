class Website
  require './app/page_filter'
  require './app/export'
#-- Summary

#  Website might be a confusing name for this class. It might be WebsiteFilter (like PageFilter),
#  but it doesn't really filter any content. Maybe WebsiteManager, but what exactly is it
#  managing? This class is a replacement for the former DirectoryScraper class. But WebsiteScraper
#  isn't a good name either- "scraping" in the context of this app seems like it should refer to
#  the scraping of content, which is what the PageFilter does.

#  So the name might change. But right now the idea is to have an object instance that remembers
#  and manages information that has to do with the site we're scraping.

#  For our immediate needs, it assumes that the site we want to scrape is on the same machine as
#  this program. But flexibility for remote directories is the long term plan. I think it's safe
#  to assume that if a client has a site on a remote server, they at least have FTP access. So
#  an FTP/SFTP class might be something to consider in the future.

  attr_accessor :root_dir, :page_paths, :config

  def initialize(root_dir, config)
    @root_path  = root_dir
    @page_paths = Dir["#{@root_path}/**/*.htm*"]
    @config     = config
  end


  def get_page_filters
    [].tap do |data|
      @page_paths.each do |path|
        data << { filename:       File.basename(path), 
                  relative_path:  path.sub(@root_path, ''),
                  filter:         PageFilter.new(path: path, config: @config) }
      end
    end
  end

  def build_site(path, options = {})
    unless options[:force]
      raise "#{path} already exists" if Dir.exists? path
    end

    pages = get_page_filters
    pages.each do |page|
      out_path = path + page[:relative_path]
      Export.to_file(page[:filter].to_html, out_path)
    end
  end

end
