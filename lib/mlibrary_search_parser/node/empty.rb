# frozen_string_literal: true
require_relative 'base'

module MLibrarySearchParser::Node
  class EmptyNode < TokensNode

    def initialize
      # nothing; just overriding
    end

    def tree_string
      "#{tree_indent}<EMPTY>"
    end

    def inspect
      "<EmptyNode>"
    end

    def node_type
      :empty
    end

    def to_s
      ""
    end

    def deep_dup
      self
    end
  end
end

