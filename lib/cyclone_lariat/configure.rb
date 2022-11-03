# frozen_string_literal: true

module CycloneLariat
  class << self
    DEFAULT_VERSION = 1

    attr_accessor :aws_key, :aws_secret_key, :publisher, :aws_default_region, :default_instance,
                  :aws_account_id, :events_dataset, :versions_dataset
    attr_writer :default_version

    def default_version
      @default_version ||= DEFAULT_VERSION
    end
  end
end
