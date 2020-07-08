module MLibrarySearchParser
  module Node
    class FieldedNode
      attr_accessor :field, :query
      def initialize(field, query)
        @field = field
        @query = query
      end

      def to_s
        "#{field}:(#{query})"
      end
    end
  end
end
