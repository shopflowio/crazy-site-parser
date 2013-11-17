require 'minitest/autorun'

class WebsiteTest < MiniTest::Unit::TestCase
  require './app/website'
  require './app/configuration'

  def setup
    config   = Configuration.new('./test/config/nokogiri.yml')
    @site_path = './test/bpd'
    @out_path  = './bpd_scraped'
    @website  = Website.new(@site_path, config)
  end

  def test_build_site
    @website.build_site('./bpd_scraped', force: true)
    original_pages  = Dir["#{@site_path}/**/*.htm*"]
    generated_pages = Dir["#{@out_path}/**/*.htm*"]

    assert generated_pages.count == original_pages.count
  end

end
