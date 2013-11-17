require 'minitest/autorun'

class ModellerTest < MiniTest::Unit::TestCase
  require './app/modeller'

  def setup
    @sqlite3_db = "./test/db/comfy_db.sqlite3"
    @db_params  = { adapter:  'sqlite3',
		    database: @sqlite3_db,
		    pool:     5,
		    timeout:  5000       }
  end


  def test_initialize_with_sqlite3
    m = Modeller.new(@db_params)

    assert !m.tables.empty?
  end

  def test_retrieve_model
    m     = Modeller.new(@db_params)
    model = m.retrieve_model 'page'

    assert model.superclass == ActiveRecord::Base
  end

end
