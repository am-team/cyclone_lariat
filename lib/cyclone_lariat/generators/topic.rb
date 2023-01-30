# frozen_string_literal: true

require 'cyclone_lariat/resources/topic'

module CycloneLariat
  module Generators
    module Topic
      def topic(type, fifo:, kind: :event, content_based_deduplication: nil, **options)
        options = CycloneLariat::Options.wrap(options)
        options.merge!(config)

        Resources::Topic.new(
          instance: options.instance,
          publisher: options.publisher,
          region: options.aws_region,
          account_id: options.aws_account_id,
          kind: kind,
          type: type,
          fifo: fifo,
          content_based_deduplication: content_based_deduplication
        )
      end

      def custom_topic(name)
        Resources::Topic.from_name(name, account_id: config.aws_account_id, region: config.aws_region)
      end
    end
  end
end
