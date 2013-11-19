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

    @models        = get_models
    @linked_fields = []
    establish_links
    @link_reader, @link_writer = IO.pipe

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
  #                  linked_fields:  {

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

  def establish_links
    # store linked fields, if any
    @page_params['link_these_fields'].each do |key, value|
      @linked_fields << { key => value }
    end
  end


  #---------------------------------------------------------------------------------#

  #- Actions -----------------------------------------------------------------------#
  def build_site(path, options = {})
    @website.build_site(path, options)
  end

  def dump_to_db
    pages = @website.get_page_filters

    for page in pages
      data     = page[:filter].parse_page
      filename = page[:filename]
      title    = data[:title]
      content  = data[:content]
      variables = assign_variables(title, filename)
puts "\n\n--------#{variables}-------------"

      @models.each do |model|
        regexp = Regexp.new(model[:referrer])
        m     = model[:model].new
        m.send(model[:content_field] + '=', content)

        @linked_fields.each do |link|
          link.each do |key, value|
	    if regexp.match value
	      attr_to_save = value.sub(regexp, '').tr('.', '')
	      @link_writer.puts attr_to_save
	    elsif regexp.match key
	      linked_field = key.sub(regexp, '').tr('.', '')
	      loaded_attr  = @link_reader.gets
	      m.send(linked_field + '=', loaded_attr)
	    end
          end
        end

        model[:static_fields].each do |field|
          field.tap do |attr, value|
            if /\$/.match value.to_s
              variables.each do |var, val|
                var = Regexp.new(var.sub(/\$/, '\$'))
                value = value.sub(var, val) if var.match value
              end
            end
            m.send(attr + '=', value)
          end
        end
	m.save!
puts m.inspect
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

  def assign_variables(title, filename)
    title_var    = { '$title'    => title }
    filename_var = { '$filename' => filename }
  end

end
