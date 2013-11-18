require 'minitest/autorun'

class ArchitectTest < MiniTest::Unit::TestCase
  require './app/architect'

  def setup
    architect_yml = './test/config/architect.yml'
    @architect    = Architect.new(architect_yml)
  end

  def test_get_models
    @architect.models.each do |model|
      assert model[:model].superclass == ActiveRecord::Base
    end
  end


end
