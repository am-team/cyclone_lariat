# frozen_string_literal: true

require 'luna_park/entities/attributable'
require 'luna_park/extensions/validatable'
require 'cyclone_lariat/messages/v2/validator'
require 'cyclone_lariat/messages/v1/validator'
require 'cyclone_lariat/errors'

module CycloneLariat
  module Messages
    module V2
      class Abstract < Message
        attrs :subject, :object

        validator Validator
      end
    end
  end
end
