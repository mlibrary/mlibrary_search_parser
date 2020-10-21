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

      def node_type
        :binary
      end

      def children
        [left, right]
      end

      def operator
        :undefined
      end

      # Equals determined by node type and equality of left/right
      # @param [BinaryNode] other The other binary node to compare
      def ==(other)
        node_type = other.node_type and
            left == other.left and
            right == other.right
      end

      def flatten
        [left.flatten, self, right.flatten].flatten
      end

      def to_s
        "(#{left}) #{operator.upcase} (#{right})"
      end

      def to_clean_string
        cs = "#{left.to_clean_string} #{operator.upcase} #{right.to_clean_string}"
        if root_node?
          cs
        else
          "(#{cs})"
        end
      end

      def trim(&blk)
        if blk.call(self)
          EmptyNode.new
        else
          self.class.new(left.trim(&blk), right.trim(&blk))
        end
      end

      # @see BaseNode#deep_dup
      def deep_dup(&blk)
        n = self.class.new(
            left.deep_dup(&blk),
            right.deep_dup(&blk))
        if block_given?
          blk.call(n)
        else
          n
        end
      end

      # Shake out stuff like title:one AND title:two to title:(one AND two)
      def shake
        if [left,right].all? {|x| x.kind_of? MLibrarySearchParser::Node::FieldedNode} and
            left.field == right.field
          FieldedNode.new(left.field, self.class.new(left.query.shake, right.query.shake))
        else
          self
        end
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
