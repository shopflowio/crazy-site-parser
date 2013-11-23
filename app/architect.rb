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

  # Scrape the site and deposit into the db
  def dump_to_db
    # First we get a hash for every page, laid out like this: { filter:        PageFilter instance,
    pages = @website.get_page_filters                        #  filename:      'the page's filename',
                                                             #  relative_path: 'the directory for the file' }
    for page in pages
      # parse_page gives us a hash with data parsed from the page, laid out like this:
      data     = page[:filter].parse_page                    #{ title:         'the page's title',
      filename = page[:filename]                             #  meta_desc:     'the meta description',
      title    = data[:title]                                #  content:       'teh scraped content' }
      content  = data[:content]

      # with this information we can now prepare our variables
      # so for every page, we render $title as data[:title] and $filename as page[:filename] 
      variables = assign_variables( title, filename )

      # now for every page, this block is called for each model listed in the yaml
      @models.each do |model|

        # the :referrer is how the model was listed in the yaml
        # the modeller is pretty smart, it'll give you the model with the closest match
        # so for cms_page, you can just put 'page', and for wp_post, 'post'
        # the Architect remembers this name from the yaml as the :referrer
        # it uses the :referrer to sub out the model name, when you put attributes like 'page.content'
        # so you can call a wp_post a 'post', but then for each attribute you must use 'post'
        # here we create our regexp, for subbing the model later from attributes stored in @linked_fields
        regexp = Regexp.new( model[:referrer] )

        # here we create a new instance of the model class, and assign the parsed content to its content field
        m     = model[:model].new
        m.send( model[:content_field] + '=', content )

        # before the linked fields, we define the static fields
        # the linked fields could have potential dependency problems otherwise
        # we already have all the info we need to define these fields
        model[:static_fields].each do |field|
          field.tap do |attr, value|

            # if the field's value is a variable, process it
            if /\$/.match value.to_s
              variables.each do |var, val|
                var = Regexp.new(var.sub(/\$/, '\$'))
                if var.match value
                  value = eval(value.sub(var, val))
                end

                #value = value.sub(var, val) if var.match value
              end
            end
            m.send(attr + '=', value) # attribute is assigned
          end
        end

        # now we begin to process the linked fields
        @linked_fields.each do |link|
          link.each do |attr_key, attr_value|

            # currently, we use an IO.pipe, @link_reader and @link_writer, to pass values between the models
            # this is just a quick hack to getting something working,
            # it'll quickly fall apart if we add more than 2 models, or more than 1 linked field

            # if the value in the field belongs to the model, we're going to retrieve it and put it in the pipe
	    if regexp.match attr_value
	      attr_to_retrieve = attr_value.sub( regexp, '' ).tr( '.', '' )

              # if the attr to retrieve is :id (which it likely is), we'll need to save the model first
              # this could be a potential dependency problem, if a validated attribute hasn't been defined
              m.save! if attr_to_retrieve == 'id'

              # now we retrieve the attribute and put it in the pipe
              retrieved_attr   = m.send( attr_to_retrieve.to_sym )
	      @link_writer.puts retrieved_attr

            # elsif this is an attribute to be ultimately saved to this model, read the value from the pipe
	    elsif regexp.match attr_key
	      linked_field   = attr_key.sub( regexp, '' ).tr( '.', '' )
	      loaded_attr    = @link_reader.gets.chomp
	      m.send( linked_field + '=', loaded_attr ) # attribute is assigned
	    end
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
