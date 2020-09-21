require "mlibrary_search_parser/node/node"
module MLibrarySearchParser::Node
  class SearchNode < BaseNode
    attr_accessor :clauses
    def initialize(clauses)
      @clauses = Array(clauses).map { |c| c.set_parent!(self) }
    end

    def multi_clause_node?
      true
    end

    def children
      clauses
    end

    def to_s
      clauses.join(" | ")
    end

    def inspect
      clauses.map(&:inspect).join(" | ")
    end

    def to_webform
      clauses.collect { |c| c.to_webform}.flatten
    end
  end
end
