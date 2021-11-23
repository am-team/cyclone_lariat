
module CycloneLariat
  module Utils
    class Hash
      def self.deep_transform_keys(object, &block)
        case object
        when ::Hash
          object.each_with_object({}) do |(key, value), result|
            result[yield(key)] = deep_transform_keys(value, &block)
          end
        when ::Array
          object.map { |e| deep_transform_keys(e, &block) }
        else
          object
        end
      end

      def self.deep_symbolize_keys(hash)
        deep_transform_keys(hash) { |key| key.to_sym rescue key }
      end
    end
  end
end
