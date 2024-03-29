# frozen_string_literal: true

require 'luna_park/values/compound'

module CycloneLariat
  class Options < LunaPark::Values::Compound
    attr_accessor :aws_key, :aws_secret_key, :publisher,
                  :aws_region, :instance, :aws_account_id,
                  :inbox_dataset, :version, :versions_dataset,
                  :driver, :fake_publish

    # @param [CycloneLariat::Options, Hash] other
    # @return [CycloneLariat::Options]
    def merge!(other)
      other = self.class.wrap(other)

      self.aws_key                       ||= other.aws_key
      self.aws_secret_key                ||= other.aws_secret_key
      self.publisher                     ||= other.publisher
      self.aws_region                    ||= other.aws_region
      self.instance                      ||= other.instance
      self.aws_account_id                ||= other.aws_account_id
      self.inbox_dataset                 ||= other.inbox_dataset
      self.version                       ||= other.version
      self.versions_dataset              ||= other.versions_dataset
      self.driver                        ||= other.driver
      self.fake_publish                  ||= other.fake_publish

      self
    end

    def merge(other)
      dup.merge!(other)
    end

    def to_h
      {
        aws_key: aws_key,
        aws_secret_key: aws_secret_key,
        publisher: publisher,
        aws_region: aws_region,
        instance: instance,
        aws_account_id: aws_account_id,
        inbox_dataset: inbox_dataset,
        version: version,
        versions_dataset: versions_dataset,
        driver: driver,
        fake_publish: fake_publish
      }
    end
  end
end
