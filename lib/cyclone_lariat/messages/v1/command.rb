# frozen_string_literal: true

require 'cyclone_lariat/messages/abstract'
require 'cyclone_lariat/messages/v1/validator'

module CycloneLariat
  module Messages
    module V1
      class Command < Abstract
        validator Validator

        KIND = 'command'

        def kind
          KIND
        end
      end
    end
  end
end
