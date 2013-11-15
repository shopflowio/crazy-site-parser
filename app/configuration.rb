class Configuration
  require './modeller'

  def initialize(options = {})
    for option in options
      raise "#{option} takes a Hash" unless option.instance_of? Hash
    end

    
  end

end
