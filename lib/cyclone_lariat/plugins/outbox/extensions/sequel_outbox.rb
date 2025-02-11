# frozen_string_literal: true

module CycloneLariat
  class Outbox
    module Extensions
      module SequelOutbox
        def transaction(**opts, &block)
          opts = Sequel::OPTS.dup.merge(opts)
          return super unless opts.delete(:with_outbox)

          outbox = CycloneLariat::Outbox.new
          result = super(**opts) do |conn|
            block.call(outbox, conn)
          end

          outbox.publish
          result
        end
      end
    end
  end
end
