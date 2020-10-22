# frozen_string_literal: true

require_relative 'base'

module MLibrarySearchParser::Node
  class EmptyNode < TokensNode
    def initialize
      # nothing; just overriding
    end

    def inspect
      "<EmptyNode>"
    end

    def node_type
      :empty
    end

    def children
      []
    end

    def to_s
      ""
    end
  end
end
