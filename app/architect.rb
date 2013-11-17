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

  require './app/*'
  require './config/global'

  attr_accessor :db_params, :models, :linked_fields

  def initialize(yml)
    @db_params   = yml['db_params']
    @page_params = yml['for_each_page']
    @models      = get_models

    @models.collect! { |m| add_params_to(m) }
  end

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
    fields = @page_params['fill_in_these_fields_with'][model[:referrer]]
    static_fields = {}

    fields.each_key do |key|
      value = fields[key]
      value = convert_if_integer(value)
      value = convert_if_boolean(value)
      static_fields.store(key, value)
    end
    model.store(:static_fields, static_fields)
  end

private

  def convert_if_integer(value)
    value.to_i if /^\d+$/.match value
  end

  def convert_if_boolean(value)
    # there has to be a better way to write this
    boolean = /^(true|false)$/.match value
    if boolean
      value = true  if boolean[1] == 'true'
      value = false if boolean[1] == 'false'
    end
    value
  end

end
