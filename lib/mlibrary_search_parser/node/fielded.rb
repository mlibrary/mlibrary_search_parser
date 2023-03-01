# frozen_string_literal: true

require_relative "base"

module MLibrarySearchParser
  module Node
    class FieldedNode < BaseNode
      attr_accessor :field, :query

      def initialize(field, query)
        @field = field
        @query = query.set_parent!(self)
      end

      def node_type
        :fielded
      end

      def children
        [query]
      end

      def shake
        shaken = query.shake
        if shaken.is_type?(:empty)
          EmptyNode.new
        else
          self.class.new(field, shaken)
        end
      end

      def deep_dup(&blk)
        n = self.class.new(field, query.deep_dup(&blk))
        if blk
          blk.call(n)
        else
          n
        end
      end

      def trim(&blk)
        self.class.new(field, query.deep_dup.trim(&blk))
      end

      def ==(other)
        other.is_type?(node_type) && other.field == field && other.query == query
      end

      def to_s
        "#{field}:(#{query})"
      end

      def clean_string
        "#{field}:#{query.clean_string}"
      end

      def tree_string
        "#{tree_indent}FIELD: #{field}\n#{query.tree_string}"
      end

      def inspect
        "<FieldedNode[#{field}]: #{query.inspect}>"
      end
    end
  end
end
