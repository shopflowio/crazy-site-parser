require 'active_record'
require 'minitest/autorun'

class ModellerTest < MiniTest::Unit::TestCase
  require './app/modeller'

  def test_initialize_with_sqlite3
    database = "./test/db/comfy_db.sqlite3"

    m = Modeller.new( adapter:  'sqlite3',
                      database: database,
                      pool:     5,
                      timeout:  5000      )

    assert !m.tables.empty?
  end

end
