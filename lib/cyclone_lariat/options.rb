# frozen_string_literal: true
require 'luna_park/values/compound'

module CycloneLariat
  class Options < LunaPark::Values::Compound
    attr_accessor :aws_key, :aws_secret_key, :publisher,
                  :aws_region, :instance, :aws_account_id,
                  :events_dataset, :version, :versions_dataset

    # @param [CycloneLariat::Options, Hash] other
    # @return [CycloneLariat::Options]
    def merge!(other)
      other = self.class.wrap(other)

      self.aws_key          ||= other.aws_key
      self.aws_secret_key   ||= other.aws_secret_key
      self.publisher        ||= other.publisher
      self.aws_region       ||= other.aws_region
      self.instance         ||= other.instance
      self.aws_account_id   ||= other.aws_account_id
      self.events_dataset   ||= other.events_dataset
      self.version          ||= other.version
      self.versions_dataset ||= other.versions_dataset

      self
    end

    def merge(other)
      dup.merge!(other)
    end
  end
end
