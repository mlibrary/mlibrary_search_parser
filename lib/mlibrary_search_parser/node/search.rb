require "mlibrary_search_parser/node/node"
module MLibrarySearchParser::Node
  class SearchNode < BaseNode
    attr_accessor :clauses
    def initialize(clauses)
      pp clauses
      @clauses = Array(clauses).map { |c| c.set_parent!(self) }
    end

    def to_s
      clauses.join(" | ")
    end

    def inspect
      clauses.map(&:inspect).join(" | ")
    end
  end
end
