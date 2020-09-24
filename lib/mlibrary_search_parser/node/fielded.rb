require "mlibrary_search_parser/node/node"
module MLibrarySearchParser
  module Node
    class FieldedNode < BaseNode
      attr_accessor :field, :query
      def initialize(field, query)
        @field = field
        @query = query.set_parent!(self)
      end
      def node_type
        :fielded
      end

      def fielded_node?
        true
      end

      def children
        [query]
      end

      def to_s
        "#{field}:(#{query})"
      end

      def to_clean_string
        "#{field}:#{query.to_clean_string}"
      end

      def inspect
        "<FieldedNode[#{field}]: #{query.inspect}>"
      end

      def to_webform
        [{"field" => field}, query.to_webform]
      end
    end
  end
end
