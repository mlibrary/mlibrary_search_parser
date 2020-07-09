require "mlibrary_search_parser/node/node"
module MLibrarySearchParser
  module Node
    class Boolean < BaseNode
      attr_accessor :left, :right
      def initialize(left, right)
        @left = left.set_parent!(self)
        @right = right.set_parent!(self)
      end

      def operator
        :undefined
      end

      def to_s
        "(#{left}) #{operator.upcase} (#{right})"
      end

      def inspect
        "<#{operator.upcase} [#{left.inspect}] [#{right.inspect}]>"
      end
    end

    class AndNode < Boolean
      def operator
        :and
      end
    end

    class OrNode < Boolean
      def operator
        :or
      end
    end

  end
end
