# frozen_string_literal: true

require_relative 'base'

module MLibrarySearchParser
  module Node
    class FieldedNode < BaseNode
      attr_accessor :field, :query

      def initialize(field, query)
        @field = field
        @query = query.set_parent!(self)
      end

      def to_s
        "#{field}:(#{query})"
      end

      def inspect
        "<FieldedNode[#{field}]: #{query.inspect}>"
      end

      def to_webform
        [{"field" => field}, query.to_webform]
      end
    end
  end
end
