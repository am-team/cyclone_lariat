# frozen_string_literal: true

require 'cyclone_lariat/messages/v2/abstract'

module CycloneLariat
  module Messages
    module V2
      class Event < Abstract
        KIND = 'event'

        def kind
          KIND
        end
      end
    end
  end
end
