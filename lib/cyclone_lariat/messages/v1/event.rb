# frozen_string_literal: true

require_relative 'abstract'

module CycloneLariat
  module Messages
    module V1
      class Event < Abstract
        KIND = 'event'

        def kind
          KIND
        end
      end
    end
  end
end
