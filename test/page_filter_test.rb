require 'minitest/autorun'
require './app/configuration'

class PageFilterTest < MiniTest::Unit::TestCase
  require './app/page_filter'

  def setup
    @config    = Configuration.new('test/config/page_filter.yml')
    @path      = 'test/bpd/Flute.html'
    @root_path = 'test/bpd/'
    @pf        = PageFilter.new( path:      @path,
                                 root_path: @root_path,
                                 config:    @config   )
  end

  def test_initialize
    assert !@pf.content.nil?
  end

  def test_parse_content
    assert @pf.parse_content.instance_of? String
    assert !@pf.parse_content.empty?
  end

  def test_images
    assert @pf.images.count == 4
  end

end
