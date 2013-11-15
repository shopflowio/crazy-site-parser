class Generate
  require './config/global'
  require 'yaml'

  def self.db_yml(options = {})
    hash = {}
    for field in Global::DB_YML_FIELDS
      value = options[field.to_sym] || nil
      hash.store(field, value)
    end

    yml_path = Global::DB_YML
    File.delete(yml_path) if File.exists? yml_path

    File.open(yml_path, 'w') do |f|
      f.write hash.to_yaml
    end
  end

end
