# frozen_string_literal: true

require_relative 'abstract'

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
