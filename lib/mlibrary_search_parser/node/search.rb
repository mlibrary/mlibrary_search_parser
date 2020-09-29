require "mlibrary_search_parser/node/node"
module MLibrarySearchParser::Node
  class SearchNode < BaseNode
    attr_accessor :clauses

    def initialize(clauses)
      # Here's the thing. Normally I'd suggest just using Array(clauses) to get an array,
      # but apparently Array#() just checks to see if you've got an enumerable. Since
      # a node _is_ an enumerable, we have to go through this rigamarole.
      c        = if clauses.kind_of? Array
                   clauses
                 else
                   [clauses]
                 end
      @clauses = Array(c).map { |c| c.set_parent!(self) }
    end

    def multi_clause_node?
      true
    end

    def node_type
      :multi
    end

    def shake
      self.class.new(clauses.map(&:shake))
    end

    def children
      clauses
    end

    def trim(&blk)
      self.class.new( clauses.map{|x| x.trim(&blk)}.reject{|x| x.empty_node?})
    end

    def to_s
      clauses.join(" | ")
    end

    def to_clean_string
      if clauses.size == 1
        str = clauses.first.to_clean_string
        if m = (/\A\((.*)\)/).match(str)
          m[1]
        else
          str
        end
      else
        str = clauses.map(&:to_clean_string).join(" ")
        if root_node?
          str
        else
          '(' + str + ')'
        end
      end
    end

    def inspect
      clauses.map(&:inspect).join(" | ")
    end

    def to_webform
      clauses.collect { |c| c.to_webform }.flatten
    end
  end
end
