# frozen_string_literal: true

require 'luna_park/values/compound'

module CycloneLariat
  module Outbox
    class Options
      attr_accessor :dataset, :republish_timeout
    end
  end
end
