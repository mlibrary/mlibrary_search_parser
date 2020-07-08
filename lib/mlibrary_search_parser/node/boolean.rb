module MLibrarySearchParser
  module Node
    class Boolean
      attr_accessor :left, :right
      def initialize(left, right)
        @left = left
        @right = right
      end

      def operator
        :undefined
      end

      def to_s
        "(#{left}) #{operator.upcase} (#{right})"
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
