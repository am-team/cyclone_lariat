# frozen_string_literal: true

require 'cyclone_lariat/messages/abstract'
require 'cyclone_lariat/messages/v1/validator'

module CycloneLariat
  module Messages
    module V1
      class Event < Abstract
        validator Validator

        KIND = 'event'

        def kind
          KIND
        end
      end
    end
  end
end
