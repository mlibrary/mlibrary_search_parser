require "mlibrary_search_parser/node/node"
module MLibrarySearchParser
  module Node
    class FieldedNode < BaseNode
      attr_accessor :field, :query
      def initialize(field, query)
        @field = field
        @query = query.set_parent!(self)
      end

      def to_s
        "#{field}:(#{query})"
      end
    end
  end
end
