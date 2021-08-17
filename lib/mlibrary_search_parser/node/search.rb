# frozen_string_literal: true

require_relative 'base'

module MLibrarySearchParser::Node
  class SearchNode < BaseNode
    attr_accessor :clauses

    def initialize(*clauses)
      @clauses = clauses.flatten.map { |c| c.set_parent!(self) }
    end

    def node_type
      :search
    end

    def children
      clauses
    end

    # @param [BaseNode] other The thing to compare to
    def ==(other)
      other.is_type?(node_type) &&
        other.clauses.size == clauses.size &&
        other.clauses.zip(clauses).all? do |n1, n2|
          n1 == n2
        end
    end

    def shake
      shaken_clauses = clauses.map(&:shake).reject {|x| x.is_type?(:empty)}
      if shaken_clauses.length > 0
        self.class.new(shaken_clauses)
      else
        EmptyNode.new
      end
    end

    def deep_dup(&blk)
      n = self.class.new(clauses.map { |c| c.deep_dup(&blk) })
      if block_given?
        blk.call(n)
      else
        n
      end
    end

    def trim(&blk)
      self.class.new(clauses.map{|c| c.trim(&blk)})
    end

    def to_s
      clauses.join(" | ")
    end

    def clean_string
      clauses.map(&:clean_string).join(' ')
    end

    # Since the search node is just a holder for multiple clauses,
    # we don't count it as deepening the tree
    def depth
      super - 1
    end

    def tree_string
      clauses.map(&:tree_string).join("\n")
    end

    def inspect
      clauses.map(&:inspect).join(" | ")
    end
  end
end
