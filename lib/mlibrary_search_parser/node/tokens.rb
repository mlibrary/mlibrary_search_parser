# frozen_string_literal: true

require_relative "base"

module MLibrarySearchParser::Node
  # A simple node to hold tokens -- either strings of text
  # or phrases
  class TokensNode < BaseNode
    attr_accessor :text

    def initialize(text)
      @text = text.to_s
    end

    def node_type
      :tokens
    end

    def to_s
      text
    end

    # Equality is having the same node type and text
    # @param [#text] other The other node
    def ==(other)
      other.is_type?(node_type) and text == other.text
    end

    # @see BaseNode#deep_dup
    def deep_dup(&blk)
      n = self.class.new(text)
      if blk
        blk.call(n)
      else
        n
      end
    end

    def shake
      if text == "*"
        EmptyNode.new
      else
        self
      end
    end

    def tree_string
      "#{tree_indent}#{clean_string}"
    end

    def inspect
      "<TokensNode: [#{text}]>"
    end
  end
end
