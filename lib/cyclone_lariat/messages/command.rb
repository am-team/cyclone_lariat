# frozen_string_literal: true

require_relative 'abstract'

module CycloneLariat
  module Messages
    class Command < Abstract
      KIND = 'command'

      def kind
        KIND
      end
    end
  end
end
