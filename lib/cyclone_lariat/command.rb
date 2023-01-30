# frozen_string_literal: true

require_relative 'abstract/message'

module CycloneLariat
  class Command < Abstract::Message
    KIND = 'command'

    def kind
      KIND
    end
  end
end
