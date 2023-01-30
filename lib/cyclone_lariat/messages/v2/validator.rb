# frozen_string_literal: true

require 'luna_park/validators/dry'
require 'cyclone_lariat/errors'

module CycloneLariat
  module Messages
    module V2
      class Validator < LunaPark::Validators::Dry
        UUID_MATCHER = /^\h{8}-\h{4}-(\h{4})-\h{4}-\h{12}$/.freeze
        ISO8601_MATCHER = /^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[0-1]|0[1-9]|[1-2][0-9])T(2[0-3]|[0-1][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[0-1][0-9]):[0-5][0-9])?$/.freeze

        validation_schema do
          params do
            required(:uuid).value(format?: UUID_MATCHER)
            required(:publisher).filled(:hash?)
            required(:type).filled(:string)
            required(:version).filled(:integer).value(eql?: 2)
            required(:data).value(:hash?)
            optional(:request_id).value(format?: UUID_MATCHER)
            required(:sent_at).value(format?: ISO8601_MATCHER)
            required(:subject).hash do
              required(:type).filled(:string)
              required(:uuid).value(format?: UUID_MATCHER)
            end
            required(:object).hash do
              required(:type).filled(:string)
              required(:uuid).value(format?: UUID_MATCHER)
            end
          end
        end

        def check!
          raise Errors::InvalidMessage.new(message: params, validation_errors: errors) unless success?
        end
      end
    end
  end
end
