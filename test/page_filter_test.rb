require 'minitest/autorun'
require './app/configuration'

class PageFilterTest < MiniTest::Unit::TestCase
  require './app/page_filter'

  def setup
    @config = Configuration.new('test/config/nokogiri.yml')
    @path   = 'test/bpd/aboutus.htm'
  end

  def test_initialize
    pf = PageFilter.new(path: @path, config: @config)

    assert !pf.content.nil?
  end

  def test_parse_content
    pf = PageFilter.new(path: @path, config: @config)
    
    assert pf.parse_content.instance_of? String
    assert !pf.parse_content.empty?
  end

end
