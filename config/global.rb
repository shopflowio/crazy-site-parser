class Global

#-- Global constants are listed here. The idea is to have a single, simple place for tweaking settings.
#   Also it helps cut down on repititions and makes everything more robust.


#- Yaml paths

#  Here we define the default paths for the configuration files. Currently there are two,
#  architect.yml and page_filter.yml.

  ARCHITECT_YML   = './config/architect.yml'

  PAGE_FILTER_YML = './config/page_filter.yml'


#- Database Configuration

#  Only the fields specified in the array will be recognized.
#  The Modeller class will ignore any option passed that doesn't exist in DB_PARAMS.
#  Generate.architect_yml will only generate fields listed here.

  DB_PARAMS = [ 'adapter',
                'database',
                'pool',
                'timeout' ]

end
