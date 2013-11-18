require 'minitest/autorun'

class ConfigurationTest < MiniTest::Unit::TestCase
  require './app/configuration'

  def setup
    @yml = './test/config/nokogiri.yml'
  end


  def test_initialization
    c = Configuration.new(@yml)

    for selector in c.selectors
      assert selector[1].instance_of?       String
    end
    assert c.seperator_string.instance_of?  String
    assert c.element_selectors.instance_of? Array
  end

end
