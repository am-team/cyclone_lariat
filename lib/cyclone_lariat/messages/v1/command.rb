# frozen_string_literal: true

require 'cyclone_lariat/messages/v1/abstract'

module CycloneLariat
  module Messages
    module V1
      class Command < Abstract
        KIND = 'command'

        def kind
          KIND
        end
      end
    end
  end
end
