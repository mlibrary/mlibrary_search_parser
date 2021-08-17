# frozen_string_literal: true
require_relative 'base'

module MLibrarySearchParser::Node
  class UnparseableNode < TokensNode

    def node_type
      :unparseable
    end

    def clean_string
      text.downcase
    end

    def tree_string
      "#{tree_indent}<UNPARSEABlE> #{clean_string}"
    end

    def inspect
      "<UnparseableNode: [#{text}]>"
    end
  end
end