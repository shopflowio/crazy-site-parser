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

  def test_images
    p @website.images
  end

end
