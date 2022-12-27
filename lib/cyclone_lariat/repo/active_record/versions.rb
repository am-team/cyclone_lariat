# frozen_string_literal: true

module CycloneLariat
  module Repo
    module ActiveRecord
      class Versions
        attr_reader :dataset

        def initialize(dataset)
          @dataset = dataset
        end

        def add(version)
          dataset.create(version: version)
          true
        end

        def remove(version)
          dataset.where(version: version).delete_all.positive?
        end

        def all
          dataset.pluck(:version).map { |version| { version: version } }
        end
      end
    end
  end
end
