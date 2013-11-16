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

namespace :config do

  task :db do
    system "clear"
    options = {}
    puts "\nPlease specify (or ^C and put a database.yml in config/)"
    puts ""
    for field in Global::DB_YML_FIELDS
      print "#{field}: "
      value = $stdin.gets
      options.store(field.to_sym, value)
    end
    Generate.db_yml(options)
  end

end

namespace :internal do

  task :confirm_db do
    system "clear"
    yml = YAML.load_file(Global::DB_YML) # rake task shouldn't have logic like this, will move
    puts "\nCurrent Database Configuration:"
    puts ""
    yml.each_key do |key|
      puts "#{key.to_s}: #{yml[key]}"
    end
    puts ""
    print "Is this okay? (y/N): "
    answer = $stdin.gets
    Rake::Task[config:db].invoke unless answer == /y/i
  end

end
