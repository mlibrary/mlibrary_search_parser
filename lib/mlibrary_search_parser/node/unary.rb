module MLibrarySearchParser
  module Node
    class Unary
      def initialize(operand)
        @operand = operand
      end

      def type
        :undefined
      end

      def to_s
        "#{type.upcase} (#{operand})"
      end
    end

    class NotNode < Unary
      def type
        :not
      end
    end
  end
end
