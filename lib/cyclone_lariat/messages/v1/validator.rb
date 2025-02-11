# frozen_string_literal: true

require 'luna_park/validators/dry'
require 'cyclone_lariat/errors'

module CycloneLariat
  module Messages
    module V1
      class Validator < LunaPark::Validators::Dry
        UUID_MATCHER = /^\h{8}-\h{4}-(\h{4})-\h{4}-\h{12}$/
        ISO8601_MATCHER = /^
          (-?(?:[1-9][0-9]*)?[0-9]{4})-
          (1[0-2]|0[1-9])-
          (3[0-1]|0[1-9]|[1-2][0-9])T
          (2[0-3]|[0-1][0-9]):
          ([0-5][0-9]):
          ([0-5][0-9])
          (\.[0-9]+)?
          (Z|[+-](?:2[0-3]|[0-1][0-9]):[0-5][0-9])?
        $/x

        validation_schema do
          params do
            required(:uuid).value(format?: UUID_MATCHER)
            required(:publisher).filled(:string)
            required(:type).filled(:string)
            required(:version).filled(:integer).value(eql?: 1)
            required(:data).value(:hash?)
            optional(:request_id).filled(:string)
            required(:sent_at).value(format?: ISO8601_MATCHER)
          end
        end

        def check!
          raise Errors::InvalidMessage.new(message: params, validation_errors: errors) unless success?
        end
      end
    end
  end
end
