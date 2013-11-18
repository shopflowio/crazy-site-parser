require './config/global'
require './app/generate'
require 'yaml'


namespace :scrape do

  task :to_comfy do
    
    # check for database.yml
    # offer to generate one if it doesn't exist
    if File.exists? Global::DB_YML
      Rake::Task[internal:confirm_db].invoke
    else
      Rake::Task[config:db].invoke
    end
    raise "FATAL: no database.yml" unless File.exists? Global::DB_YML

    # ask for directory to scrape
    # do it
  end

  # proof of concept
  # so we can at least get back to a working scraper
  task :to_html do

  end

end
