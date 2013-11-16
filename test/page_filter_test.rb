require 'minitest/autorun'
require './app/configuration'

class PageFilterTest < MiniTest::Unit::TestCase
  require './app/page_filter'

  def setup
    @config = Configuration.new('test/config/nokogiri.yml')
    @path   = 'test/bpd/aboutus.htm'
  end

  def test_initialization
    page_filter = PageFilter.new(path: @path, config: @config)

    page_filter.tap do
      assert config.instance_of? Configuration

      [doc, title, meta_description, content].each do |ivar|
        assert ivar.instance_of? Nokogiri::HTML
      end
    end
  end

end
