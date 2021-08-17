# frozen_string_literal: true

require_relative 'base'

module MLibrarySearchParser
  module Node

    class UnaryNode < BaseNode
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

      def tree_string
        "#{tree_indent}#{operator.to_s.upcase}\n#{operand.tree_string}"
      end

      def deep_dup(&blk)
        n = self.class.new(operand.deep_dup(&blk))
        if block_given?
          blk.call(n)
        else
          n
        end
      end

      def ==(other)
        other.is_type?(node_type) && operand == other.operand
      end

      def inspect
        "<#{operator.upcase} [#{operand.inspect}]>"
      end

      def shake
        shaken = operand.shake

        return EmptyNode.new if shaken.is_type?(:empty)
        self.class.new(shaken)
      end
    end

    class NotNode < UnaryNode
      def operator
        :not
      end

      def node_type
        :not
      end
    end

  end
end