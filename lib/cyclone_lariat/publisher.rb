# frozen_string_literal: true

require 'cyclone_lariat/clients/sns'
require 'cyclone_lariat/clients/sqs'

module CycloneLariat
  class Publisher
    include Generators::Event
    include Generators::Command

    attr_reader :config

    def initialize(**options)
      @config = CycloneLariat::Options.wrap(options).merge!(CycloneLariat.config)
    end

    def sqs
      @sqs ||= Clients::Sqs.new(**config.to_h)
    end

    def sns
      @sns ||= Clients::Sns.new(**config.to_h)
    end
  end
end
