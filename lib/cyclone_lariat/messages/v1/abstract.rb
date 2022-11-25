# frozen_string_literal: true

require 'luna_park/entities/attributable'
require 'cyclone_lariat/errors'

module CycloneLariat
  module Messages
    module V1
      class Abstract < LunaPark::Entities::Attributable
        attr :uuid,       String, :new
        attr :publisher,  String, :new
        attr :type,       String, :new
        attrs :client_error, :version, :data, :request_id,
              :sent_at, :processed_at, :received_at

        def kind
          raise LunaPark::Errors::AbstractMethod
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

        def request_at=(value)
          @request_id = wrap_string(value)
        end

        def processed?
          !@processed_at.nil?
        end

        def client_error_message=(txt)
          return unless txt

          @client_error ||= Errors::ClientError.new
          @client_error.message = txt
        end

        def client_error_details=(details)
          return unless details

          @client_error ||= Errors::ClientError.new
          @client_error.details = details
        end

        def ==(other)
          kind == other.kind &&
            uuid == other.uuid &&
            publisher == other.publisher &&
            type == other.type &&
            client_error&.message == other.client_error&.message &&
            version == other.version &&
            sent_at.to_i == other.sent_at.to_i &&
            received_at.to_i == other.received_at.to_i &&
            processed_at.to_i == other.processed_at.to_i
        end

        def to_json(*args)
          hash = serialize
          hash[:type]         = [kind, hash[:type]].join '_'
          hash[:sent_at]      = hash[:sent_at].iso8601(3)      if hash[:sent_at]
          hash[:received_at]  = hash[:received_at].iso8601(3)  if hash[:received_at]
          hash[:processed_at] = hash[:processed_at].iso8601(3) if hash[:processed_at]
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

        def wrap_string(value)
          case value
          when String then String(value)
          when NilClass then nil
          else raise ArgumentError, "Unknown type `#{value.class}`"
          end
        end
      end
    end
  end
end
