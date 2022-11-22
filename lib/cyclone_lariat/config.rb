# frozen_string_literal: true
require 'luna_park/values/compound'

module CycloneLariat
  class Config < LunaPark::Values::Compound
    attr_accessor :aws_key, :aws_secret_key, :publisher,
                  :aws_region, :instance, :aws_account_id,
                  :events_dataset, :version, :versions_dataset

    def merge!(other)
      %i[
        aws_key aws_secret_key publisher aws_region aws_account_id
        instance events_dataset version versions_dataset
      ].each do |option|
        public_send(:"#{option}=", other.public_send(option)) if public_send(option).nil?
      end

      self
    end
  end

  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield(config)
    end
  end
end
