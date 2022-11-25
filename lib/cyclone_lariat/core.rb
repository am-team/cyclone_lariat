# frozen_string_literal: true

require 'cyclone_lariat/generators/queue'
require 'cyclone_lariat/generators/topic'
require 'cyclone_lariat/options'

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
