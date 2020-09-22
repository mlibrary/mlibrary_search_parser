require "mlibrary_search_parser/node/node"
module MLibrarySearchParser::Node
  class SearchNode < BaseNode
    attr_accessor :clauses
    def initialize(clauses)
      # Here's the thing. Normally I'd suggest just using Array(clauses) to get an array,
      # but apparently Array#() just checks to see if you've got an enumerable. Since
      # a node _is_ an enumerable, we have to go through this rigamarole.
      c = if clauses.kind_of? Array
            clauses
          else
            [clauses]
          end
      @clauses = Array(c).map { |c| c.set_parent!(self) }
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
      # clauses.collect { |c| c.to_webform}.flatten
      clauses.flat_map{|c| c.to_webform}.flatten
    end
  end
end
