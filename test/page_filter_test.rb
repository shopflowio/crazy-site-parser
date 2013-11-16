require 'minitest/autorun'
require './app/configuration'

class PageFilterTest < MiniTest::Unit::TestCase
  require './app/page_filter'

  def setup
    @config = Configuration.new('test/config/nokogiri.yml')
    @path   = 'test/bpd/aboutus.htm'
  end

  def test_initialization
    pf = PageFilter.new(path: @path, config: @config)

    assert pf.content.instance_of? Nokogiri::XML::Element
  end

end
