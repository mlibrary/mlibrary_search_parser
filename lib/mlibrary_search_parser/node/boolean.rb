require "mlibrary_search_parser/node/node"
module MLibrarySearchParser
  module Node
    class Boolean < BaseNode
      def self.for_operator(operator, left, right=nil)
        case operator.upcase
        when "OR"
          OrNode.new(left, right)
        when "AND"
          AndNode.new(left, right)
        when "NOT"
          AndNode.new(left, NotNode.new(right))
        end
      end
    end

    class BinaryNode < Boolean
      attr_accessor :left, :right
      def initialize(left, right)
        @left = left.set_parent!(self)
        @right = right.set_parent!(self)
      end

      def binary_node?
        true
      end

      def children
        [left, right]
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

      def to_webform
        [left.to_webform, {"operator" => "#{operator.upcase}"}, right.to_webform].flatten
      end
    end

    class AndNode < BinaryNode
      def operator
        :and
      end

      def and_node?
        true
      end
    end

    class OrNode < BinaryNode
      def operator
        :or
      end

      def or_node?
        true
      end
    end

    class UnaryNode < Boolean
      attr_accessor :operand
      def initialize(operand)
        @operand = operand
      end

      def operator
        :undefined
      end

      def children
        [operand]
      end

      def to_s
        "#{operator.upcase} (#{operand})"
      end

      def inspect
        "<#{operator.upcase} [#{operand.inspect}]>"
      end

      def to_webform
        [{"operator" => "#{operator.upcase}"}, operand.to_webform]
      end
    end

    class NotNode < UnaryNode
      def operator
        :not
      end

      def not_node?
        true
      end
    end

  end
end
