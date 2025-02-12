# frozen_string_literal: true

module CycloneLariat
  module Resources
    class Topic
      SNS_SUFFIX = :fanout

      attr_reader :instance, :kind, :region, :account_id, :publisher, :type, :fifo, :content_based_deduplication

      def initialize(instance:, kind:, region:, account_id:, publisher:, type:, fifo:,
                     content_based_deduplication: nil, tags: nil, name: nil)
        @instance  = instance
        @kind      = kind
        @region    = region
        @account_id = account_id
        @publisher = publisher
        @type      = type
        @fifo      = fifo
        @tags      = tags
        @name      = name
        @content_based_deduplication = content_based_deduplication
      end

      def arn
        ['arn', 'aws', 'sns', region, account_id, to_s].join ':'
      end

      def custom?
        !standard?
      end

      def standard?
        return false unless instance && kind && publisher && type

        true
      end

      def name
        @name ||= begin
          name = [instance, kind, SNS_SUFFIX, publisher, type].compact.join '-'
          name += '.fifo' if fifo
          name
        end
      end

      def attributes
        attrs = {}
        attrs['FifoTopic']                 = 'true' if fifo
        attrs['ContentBasedDeduplication'] = 'true' if content_based_deduplication
        attrs
      end

      def topic?
        true
      end

      def queue?
        false
      end

      def protocol
        'sns'
      end

      alias to_s name

      def ==(other)
        arn == other.arn
      end

      class << self
        def from_name(name, region:, account_id:)
          is_fifo_array  = name.split('.')
          full_name      = is_fifo_array[0]
          fifo_suffix    = is_fifo_array[-1]
          suffix_exists  = fifo_suffix != full_name

          if suffix_exists && fifo_suffix != 'fifo'
            raise ArgumentError, "Topic name #{name} consists unexpected suffix #{fifo_suffix}"
          end

          fifo = suffix_exists
          topic_array = full_name.split('-')

          raise ArgumentError, "Topic name should consists `#{SNS_SUFFIX}`" unless topic_array[2] != SNS_SUFFIX

          topic_array.clear if topic_array.size < 5

          new(
            instance: topic_array[0],
            kind: topic_array[1],
            publisher: topic_array[3],
            type: topic_array[4],
            region: region,
            account_id: account_id,
            fifo: fifo,
            name: name
          )
        end

        def from_arn(arn)
          arn_array = arn.split(':')
          raise ArgumentError, 'Arn should consists `arn`' unless arn_array[0] == 'arn'
          raise ArgumentError, 'Arn should consists `aws`' unless arn_array[1] == 'aws'
          raise ArgumentError, 'Arn should consists `sns`' unless arn_array[2] == 'sns'

          from_name(arn_array[5], region: arn_array[3], account_id: arn_array[4])
        end
      end

      def tags
        @tags ||= if standard?
                    [
                      { key: 'standard',  value: 'true' },
                      { key: 'instance',  value: String(instance) },
                      { key: 'kind',      value: String(kind) },
                      { key: 'publisher', value: String(publisher) },
                      { key: 'type',      value: String(type) },
                      { key: 'fifo',      value: fifo ? 'true' : 'false' }
                    ]
                  else
                    [
                      { key: 'standard',  value: 'false' },
                      { key: 'name',      value: String(name) },
                      { key: 'fifo',      value: fifo ? 'true' : 'false' }
                    ]
                  end
      end
    end
  end
end
