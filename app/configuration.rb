class Configuration
  require 'yaml'

#-- Summary

#  A Configuration object is initialized with a yaml file, by default config/nokogiri.yml.
#  The yaml file defines the nokogiri logic for each selector (title, meta_description and content).
#  It also defines element selectors and a seperater string to seperate them with.

#  Each PageFilter gets initialized with a Configuration object (probably the same one for all of them).
#  Every selector will get evaluated as a statement within an instance of Nokogiri object.
#  So just about every value in the yaml file gets evaluated as ruby code, and we can use Nokogiri methods.

#  The one exception is the seperater string, which will always remain a string.

  attr_accessor :selectors, :element_selectors, :seperator_string, :elements_to_seperate,
                :encoding, :condense_spaces, :characters_to_strip

  def initialize(yml_path)
    raise "Cannot find #{yml_path}" unless File.exists? yml_path
    yml = YAML.load_file(yml_path)

    @selectors = { title_selector:            yml['title_selector'],
                   meta_description_selector: yml['meta_description_selector'],
                   content_selector:          yml['content_selector']        }

    @element_selectors    =                   yml['element_selectors']
    @seperator_string     =                   yml['seperator_string']
    @elements_to_seperate =                   yml['elements_to_seperate']
    @encoding             =                   yml['encode_html_as']
    @condense_spaces      =                   yml['condense_spaces']
    @characters_to_strip  =                   yml['characters_to_strip']
  end

end
