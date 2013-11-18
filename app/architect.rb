require 'debugger'
class Architect
#-- Summary

#  Yes, like the old guy from The Matrix. This is the class that orchestrates things
#  from above. It has knowledge of all the other classes, but doesn't do any of
#  the work. It just gives the orders.

#  The Architect receives its instructions from architect.yml, a user-level config
#  file. This file tells it which models it should know about, which models to link
#  and which of their fields to link, which fields should remain static and have the
#  same value for each transaction, etc.

#  This is a new idea, fresh from the coffee pot. So I'll probably continue to develop
#  the concept over the course of the day.

#  For convention, keys we set are symbols, and keys they set are strings.

  require './app/modeller'
  require './app/configuration'
  require './app/website'
  require './config/global'

  attr_accessor :db_params, :models, :website

  def initialize(yml_path = nil)
    yml = YAML.load_file(yml_path || Global::ARCHITECT_YML)

    @db_params   = yml['db_params']
    @page_params = yml['for_each_page']

    symbolize_keys(@db_params)

    @models      = get_models
    @models.each do |model|
      add_params_to(model)
    end
    
    filter_config = Configuration.new(Global::PAGE_FILTER_YML)
    @website      = Website.new(yml['website_directory'], filter_config)
  end


  #- Model preparation --------------------------------------------------------------#

  # model_layout = { model:          ActualModel,
  #                  referrer:       name of model in yml (like "page", instead of "CmsPage"),
  #                  content_field:  name of the content field on the model,
  #                  static_fields:  { 'each_field' => we keep these keys as strings,
  #                                    'etc'        => the list goes on              }

  def get_models
    [].tap do |models|
      for model in @page_params['create_new']
	m = Modeller.new(@db_params)
	models << { model:    m.retrieve_model(model),
                    referrer: model                 }
      end
    end
  end

  def add_params_to(model)
    regexp = Regexp.new(model[:referrer])

    # define the model's content field
    for field in @page_params['dump_content_into']
      if regexp.match(field)
        model.store(:content_field, field.sub(regexp, '').tr('.', ''))
      end
    end

    # define the model's static fields
    fields = @page_params['fill_these_fields_with'][model[:referrer]]
    static_fields = {}

    fields.each_key do |key|
      static_fields.store(key, fields[key])
    end
    model.store(:static_fields, static_fields)
  end
  #---------------------------------------------------------------------------------#

  #- Actions -----------------------------------------------------------------------#
  def build_site(path, options = {})
    @website.build_site(path, options)
  end

  def dump_to_db
    pages = @website.get_page_filters

    for page in pages
      content = page[:filter].parse_content
      @models.each do |model|
        m =             model[:model].new
        m.send(         model[:content_field], content)
        for field in    model[:static_fields]
          m.send(field, model[:static_fields][field])
        end
        m.save!
      end
    end
  end



private

  def symbolize_keys(hash)
  # this is taken from Rails
    hash.keys.each do |k|
      hash[(k.to_sym rescue k) || k] = hash.delete(k)
    end
  end

end
