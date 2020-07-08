module MLibrarySearchParser
  module Node
    class Unary
      attr_accessor :operand
      def initialize(operand)
        @operand = operand
      end

      def operator
        :undefined
      end

      def to_s
        "#{operator.upcase} (#{operand})"
      end
    end

    class NotNode < Unary
      def operator
        :not
      end
    end
  end
end
