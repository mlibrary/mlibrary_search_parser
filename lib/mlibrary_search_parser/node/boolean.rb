# frozen_string_literal: true

require_relative 'base'

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
    end

    class OrNode < BinaryNode
      def operator
        :or
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
    end

  end
end
