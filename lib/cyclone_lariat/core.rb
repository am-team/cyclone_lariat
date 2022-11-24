require_relative 'generators/queue'
require_relative 'generators/topic'
require_relative 'options'

module CycloneLariat
  module CycloneLariatMethods
    def config
      @config ||= Options.new
    end

    def configure
      yield(config)
    end
  end

  extend Generators::Topic
  extend Generators::Queue
  extend CycloneLariatMethods
end
