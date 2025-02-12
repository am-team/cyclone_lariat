# frozen_string_literal: true

module CycloneLariat
  class Outbox
    module Extensions
      module ActiveRecordOutbox
        def transaction(opts = {}, &block)
          opts = opts.dup
          return super(**opts, &block) unless opts.delete(:with_outbox)

          outbox = CycloneLariat::Outbox.new
          result = super(**opts) do
            block.call(outbox)
          end

          outbox.publish
          result
        end
      end
    end
  end
end
