# frozen_string_literal: true
require 'uri'

module CycloneLariat
  class Queue
    SNS_SUFFIX = :queue

    attr_reader :instance, :kind, :region, :dest, :account_id, :publisher, :type, :fifo, :tags

    def initialize(instance:, kind:, region:, dest:, account_id:, publisher:, type:, fifo:, tags: nil, name: nil)
      @instance  = instance
      @kind      = kind
      @region    = region
      @dest      = dest
      @account_id = account_id
      @publisher = publisher
      @type      = type
      @fifo      = fifo
      @tags      = tags || default_tags(instance, kind, publisher, type, dest, fifo)
      @name      = name
    end

    def arn
      ['arn', 'aws', 'sqs', region, account_id, name].join ':'
    end

    ##
    # Url example:
    #  https://sqs.eu-west-1.amazonaws.com/247606935658/stage-event-queue
    def url
      "https://sqs.#{region}.amazonaws.com/#{account_id}/#{name}"
    end

    def custom?
      !standard?
    end

    def standard?
      instance && kind && publisher && type && true
    end

    def name
      @name ||= begin
        name = [instance, kind, SNS_SUFFIX, publisher, type, dest].compact.join '-'
        name += '.fifo' if fifo
        name
      end
    end

    alias to_s name

    class << self
      ##
      # Name example: test-event-queue-cyclone_lariat-note_added.fifo
      # instance: teste
      # kind: event
      # publisher: cyclone_lariat
      # type: note_added
      # dest: nil
      # fifo: true
      def from_name(name, region:, account_id:)
        is_fifo_array  = name.split('.')
        full_name      = is_fifo_array[0]
        fifo_suffix    = is_fifo_array[-1]
        suffix_exists  = fifo_suffix != full_name

        raise ArgumentError, "Queue name #{name} consists unexpected suffix #{fifo_suffix}" if suffix_exists && fifo_suffix != 'fifo'

        fifo = suffix_exists
        queue_array = full_name.split('-')

        raise ArgumentError, "Topic name should consists `#{SNS_SUFFIX}`" unless queue_array[2] != SNS_SUFFIX

        new(
          instance: queue_array[0],
          kind: queue_array[1],
          region: region,
          dest: queue_array[5],
          account_id: account_id,
          publisher: queue_array[3],
          type: queue_array[4],
          fifo: fifo,
          name: name
        )
      end

      ##
      # URL example: https://sqs.eu-west-1.amazonaws.com/247606935658/test-event-queue-cyclone_lariat-note_added.fifo
      # url_array[0]  => https
      # host_array[0] => sqs
      # host_array[1] => eu-west-1
      # url_array[3]  => 247606935658 # account_id
      # url_array[4]  => test-event-queue-cyclone_lariat-note_added.fifo # name
      def from_url(url)
        raise ArgumentError, 'Url is not http format' unless url =~ URI.regexp

        url_array = url.split('/')
        raise ArgumentError, 'Url should start from https' unless url_array[0] == 'https:'

        host_array = url_array[2].split('.')
        raise ArgumentError, 'It is not queue url' unless host_array[0] == 'sqs'

        from_name(url_array[4], region: host_array[1] , account_id: url_array[3])
      end

      ##
      # Arn example: "arn:aws:sqs:eu-west-1:247606935658:custom_queue"
      # arn_array[0] => 'arn'
      # arn_array[1] => 'aws'
      # arn_array[2] => 'sqs'
      # arn_array[3] => 'eu-west-1'     # region
      # arn_array[4] => '247606935658'  # account_id
      # arn_array[5] => 'alexey_test2'  # name
      def from_arn(arn)
        arn_array = arn.split(':')

        raise ArgumentError, "Arn `#{arn}` should consists `arn`" unless arn_array[0] == 'arn'
        raise ArgumentError, "Arn `#{arn}` should consists `aws`" unless arn_array[1] == 'aws'
        raise ArgumentError, "Arn `#{arn}` should consists `sqs`" unless arn_array[2] == 'sqs'

        from_name(arn_array[5], region: arn_array[3], account_id: arn_array[4])
      end
    end

    private

    def default_tags(instance, kind, publisher, type, dest, fifo)
      {
        instance:    String(instance),
        kind:        String(kind),
        publisher:   String(publisher),
        type:        String(type),
        dest: dest ? String(dest) : 'undefined',
        fifo: fifo ? 'true' : 'false'
      }
    end
  end
end
