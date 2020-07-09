require "mlibrary_search_parser/node/node"
module MLibrarySearchParser
  module Node
    class Unary < BaseNode
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

      def inspect
        "<#{operator.upcase} [#{operand.inspect}]>"
      end
    end

    class NotNode < Unary
      def operator
        :not
      end
    end
  end
end
