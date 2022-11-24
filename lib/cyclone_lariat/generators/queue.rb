require_relative '../resources/queue'

module CycloneLariat
  module Generators
    module Queue
      def queue(type = :all, fifo:, dest: nil, kind: :event, **options)
        options = CycloneLariat::Options.wrap(options)
        options.merge!(config)

        Resources::Queue.new(
          instance: options.instance,
          publisher: options.publisher,
          region: options.aws_region,
          account_id: options.aws_account_id,
          kind: kind,
          type: type,
          fifo: fifo,
          dest: dest
        )
      end

      def custom_queue(name)
        Resources::Queue.from_name(name, account_id: config.aws_account_id, region: config.aws_region)
      end
    end
  end
end
