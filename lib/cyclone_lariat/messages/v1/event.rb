# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/abstract'

module CycloneLariat
  module Messages
    module V1
      class Event < Abstract
        include LunaPark::Extensions::Validatable
        validator Messages::V1::Validator

        KIND = 'event'

        def kind
          KIND
        end
      end
    end
  end
end
