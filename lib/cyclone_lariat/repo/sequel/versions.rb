# frozen_string_literal: true

module CycloneLariat
  module Repo
    module Sequel
      class Versions
        attr_reader :dataset

        def initialize(dataset)
          @dataset = dataset
        end

        def add(version)
          dataset.insert(version: version)
        end

        def remove(version)
          dataset.filter(version: version).delete
        end

        def all
          dataset.all
        end
      end
    end
  end
end
