class Global

#-- Global constants are listed here. The idea is to have a single, simple place for tweaking settings.
#   Also it helps cut down on repititions and makes everything more robust.


#- Database Configuration

#  The database.yml can contain anything, but only the fields specified in the array will be recognized.
#  The Modeller class will ignore any option passed that doesn't exist in DB_YML_FIELDS
#  Generate.db_yml will only generate fields listed here.
#  rake tasks will only display and consider fields listed here.

  DB_YML        = './config/database.yml'

  DB_YML_FIELDS = [ 'adapter',
                    'database',
                    'pool',
                    'timeout' ]

end
