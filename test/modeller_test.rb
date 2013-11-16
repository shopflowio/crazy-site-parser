require 'active_support'

class ModellerTest < ActiveSupport::TestCase
  require './app/modeller'

  test "initialize with sqlite3" do
    database = "./test/db/comfy_db.sqlite3"

    m = Modeller.new( adapter:  'sqlite3',
                      database: database,
                      pool:     5,
                      timeout:  5000      )

    !assert_raise ActiveRecord::ConnectionNotEstablished do
      m.connection
    end
  end

end
