require './app/architect'

namespace :scrape do

  task :to_db do
    a = Architect.new
    a.dump_to_db
  end

  task :images do
    a = Architect.new
    a.export_images
  end

  task :to_folder do
  end

end
