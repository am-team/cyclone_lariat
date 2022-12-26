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
        end

        def remove(version)
          dataset.where(version: version).delete_all
        end

        def all
          dataset.all
        end
      end
    end
  end
end
