class Modeller
  require './config/global'
  require 'active_record'
  require 'sqlite3'

#-- Summary

#  Modeller is a class that connects to databases and basically wraps ActiveRecord::Base, but also
#  retrieves or dynamically creates the appropriate ActiveRecord models.

#  The job right now is just to interact with Comfy Mexican Sofa, but I think if written the right way
#  it can work with Wordpress too, and other CMS's.


  attr_accessor :connection

  def initialize(options = {})
    valid_params = {}
    if options[:adapter] and options[:database]
      options.each_key do |key|
        if Global::DB_YML_FIELDS.include? key.to_s
          valid_params.store(key, options[key])
        end
      end
      ActiveRecord::Base.establish_connection(valid_params)
      @connection = ActiveRecord::Base.connection
    else
      raise "Adapter and database must be specified"
    end
  end

  def tables
    @connection.tables
  end


#-- method for retrieving an ActiveRecord::Base model
  def retrieve_model(regexp)
    regexp = Regexp.new(regexp) if regexp.instance_of? String
    raise "Arguement takes a String or Regexp" unless regexp.instance_of? Regexp

    # first check to see if any table names match the regexp.
    # ensure there is only one match
    matching_tables = []
    for table in tables
      matching_tables << table if regexp.match(table)
    end

    if matching_tables.empty?
      return nil
    elsif matching_tables.count > 1
      raise "Several tables match #{regexp}: #{matching_tables * ', '}"
    else
      # now we check to see if a model with that name already exists
      # if one does, check to see that it inherits from ActiveRecord::Base
      # return model if it's valid, else create a new one and return that
      table = matching_tables.pop
      model_name = table.camelize
      model_name.chop! if model_name[-1] == 's'

      if defined? model_name.constantize == 'constant'
        model = model_name.constantize
        unless model.superclass == ActiveRecord::Base
          raise "#{model_name} exists, but doesn't inherit from ActiveRecord::Base"
        end
        return model
      else
        Object.const_set(model_name, Class.new(ActiveRecord::Base))
        model = model_name.constantize
        return model
      end
    end
  end

end
