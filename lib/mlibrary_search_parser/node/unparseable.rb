# frozen_string_literal: true
require_relative 'base'

module MLibrarySearchParser::Node
  class UnparseableNode < TokensNode

    def node_type
      :unparseable
    end

    def children
      []
    end

    def inspect
      "<UnparseableNode: [#{text}]>"
    end
  end
end