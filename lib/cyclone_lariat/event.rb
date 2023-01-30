# frozen_string_literal: true

require_relative 'abstract/message'

module CycloneLariat
  class Event < Abstract::Message
    KIND = 'event'

    def kind
      KIND
    end
  end
end
