require 'luna_park/errors/system'

module CycloneLariat
  module Errors
    class TopicNotFound < LunaPark::Errors::System
      message { |d| "Could not found topic: `#{d[:expected_topic]}`" }
    end
  end
end
