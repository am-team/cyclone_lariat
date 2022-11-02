# frozen_string_literal: true

module CycloneLariat
  class Topic
    SNS_SUFFIX = :fanout

    attr_reader :instance, :kind, :region, :client_id, :publisher, :type, :fifo, :tags

    def initialize(instance:, kind:, region:, client_id:, publisher:, type:, fifo:, tags: nil, name: nil)
      @instance  = instance
      @kind      = kind
      @region    = region
      @client_id = client_id
      @publisher = publisher
      @type      = type
      @fifo      = fifo
      @tags      = tags || default_tags(instance, kind, publisher, type, fifo)
      @name      = name
    end

    def arn
      ['arn', 'aws', 'sns', region, client_id, to_s].join ':'
    end

    def custom?
      !standard?
    end

    def standard?
      instance && kind && publisher && type
    end

    def name
      @name ||= begin
        name = [instance, kind, SNS_SUFFIX, publisher, type].join '-'
        name += '.fifo' if fifo
        name
      end
    end

    def attributes
      fifo ? { 'FifoTopic' => 'true' } : {}
    end

    alias to_s name

    def ==(other)
      arn == other.arn
    end

    class << self
      def from_name(name, region:, client_id:)
        is_fifo_array  = name.split('.')
        full_name      = is_fifo_array[0]
        fifo_suffix    = is_fifo_array[-1]
        suffix_exists  = fifo_suffix != full_name

        raise ArgumentError, "Topic name #{name} consists unexpected suffix #{fifo_suffix}" if suffix_exists && fifo_suffix != 'fifo'

        fifo = suffix_exists
        topic_array = full_name.split('-')

        raise ArgumentError, "Topic name should consists `#{SNS_SUFFIX}`" unless topic_array[2] != SNS_SUFFIX

        new(
          instance: topic_array[0],
          kind: topic_array[1],
          publisher: topic_array[3],
          type: topic_array[4],
          region: region,
          client_id: client_id,
          fifo: fifo,
          name: name
        )
      end

      def from_arn(arn)
        arn_array = arn.split(':')
        raise ArgumentError, 'Arn should consists `arn`' unless arn_array[0] == 'arn'
        raise ArgumentError, 'Arn should consists `aws`' unless arn_array[1] == 'aws'
        raise ArgumentError, 'Arn should consists `aws`' unless arn_array[2] == 'sns'

        from_name(arn_array[5], region: arn_array[3], client_id: arn_array[4])
      end
    end

    private

    def default_tags(instance, kind, publisher, type, fifo)
      [
        { key: 'instance',  value: String(instance) },
        { key: 'kind',      value: String(kind) },
        { key: 'publisher', value: String(publisher) },
        { key: 'type',      value: String(type) },
        { key: 'fifo',      value: fifo ? 'true' : 'false' },
      ]
    end
  end
end
