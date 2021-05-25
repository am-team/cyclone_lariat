# frozen_string_literal: true

require 'luna_park/entities/attributable'

module CycloneLariat
  class Event < LunaPark::Entities::Attributable
    KIND = 'event'

    attr :uuid,      String, :new
    attr :publisher, String, :new
    attr :type,      String, :new
    attr :version
    attr :data

    attr_reader :sent_at,
                :processed_at,
                :received_at

    def kind
      KIND
    end

    def version=(value)
      @version = Integer(value)
    end

    def sent_at=(value)
      @sent_at = wrap_time(value)
    end

    def received_at=(value)
      @received_at = wrap_time(value)
    end

    def processed_at=(value)
      @processed_at = wrap_time(value)
    end

    def to_json(*args)
      hash = serialize
      hash[:type] = [kind, hash[:type]].join '_'
      hash.to_json(*args)
    end

    private

    def wrap_time(value)
      case value
      when String   then Time.parse(value)
      when Time     then value
      when NilClass then nil
      else raise ArgumentError, "Unknown type `#{value.class}`"
      end
    end
  end
end
