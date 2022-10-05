# frozen_string_literal: true

module CycloneLariat
  class << self
    DEFAULT_VERSION = 1

    attr_accessor :key, :secret_key, :publisher, :default_region, :default_instance
    attr_writer :default_version

    def default_version
      @default_version ||= DEFAULT_VERSION
    end
  end
end
