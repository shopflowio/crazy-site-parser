require 'minitest/autorun'

class ArchitectTest < MiniTest::Unit::TestCase
  require './app/architect'
  require 'fileutils'

  def setup
    FileUtils.copy('./test/db/comfy_db_backup.sqlite3', './test/db/comfy_db.sqlite3')
    architect_yml = './test/config/architect.yml'
    @architect    = Architect.new(architect_yml)
  end

  def test_get_models
    @architect.models.each do |model|
      assert model[:model].superclass == ActiveRecord::Base
    end
  end

  def test_dump_to_db
    # not sure how to test this without running every other class
    model     = @architect.models.first[:model]
    old_count = model.count
    @architect.dump_to_db
    assert model.count > old_count
    model.all.sample(2).tap do |m1, m2|
      assert m1.slug != m2.slug
    end
  end

  def test_export_images
    @architect.export_images
    exported_images = Dir.entries(@architect.image_folder)
    assert exported_images.count >= @architect.website.images.count 
  end

end
