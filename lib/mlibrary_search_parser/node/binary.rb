# frozen_string_literal: true

require_relative 'base'

module MLibrarySearchParser
  module Node
    class BinaryNode < BaseNode
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
        other.is_type?(node_type) and
            left == other.left and
            right == other.right
      end

      def flatten
        [left.flatten, self, right.flatten].flatten
      end

      def to_s
        "(#{left}) #{operator.upcase} (#{right})"
      end

      def clean_string
        cs = "#{left.clean_string} #{operator.upcase} #{right.clean_string}"
        if root_node?
          cs
        else
          "(#{cs})"
        end
      end

      def tree_string
        ["#{tree_indent}#{operator.to_s.upcase}", left.tree_string, right.tree_string].join("\n")
      end

      def trim(&blk)
        if blk.call(self)
          EmptyNode.new
        else
          trimmed_left = left.trim(&blk)
          trimmed_right = right.trim(&blk)
          combo = [trimmed_left, trimmed_right].map{|n| n.is_type?(:empty) ? :empty : :not_empty}
          case combo
          when [:empty, :empty]
            EmptyNode
          when [:not_empty, :empty]
            trimmed_left
          when [:empty, :not_empty]
            trimmed_right
          when [:not_empty, :not_empty]
            self.class.new(trimmed_left, trimmed_right)
          end
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
        lshake = left.shake
        rshake = right.shake

        return EmptyNode.new if  [lshake, rshake].all? {|n| n.is_type?(:empty)}
        return lshake if rshake.is_type?(:empty)
        return rshake if lshake.is_type?(:empty)
        if lshake == rshake
          lshake
        elsif [left,right].all? {|x| x.is_type?(:fielded)} and
            left.field == right.field
          FieldedNode.new(left.field, self.class.new(left.query.shake, right.query.shake))
        else
          self
        end
      end

      def inspect
        "<#{operator.upcase} [#{left.inspect}] [#{right.inspect}]>"
      end
    end

    class AndNode < BinaryNode
      def operator
        :and
      end

      def node_type
        :and
      end
    end

    class OrNode < BinaryNode
      def operator
        :or
      end

      def node_type
        :or
      end
    end



  end
end
