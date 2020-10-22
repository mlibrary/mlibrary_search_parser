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
      self.class.new(clauses.map(&:shake))
    end

    def deep_dup(&blk)
      n = self.class.new(clauses.map { |c| c.deep_dup(&blk) })
      if block_given?
        blk.call(n)
      else
        n
      end
    end

    def to_s
      clauses.join(" | ")
    end

    def to_clean_string
      clauses.map(&:to_clean_string).join(' ')
    end

    def inspect
      clauses.map(&:inspect).join(" | ")
    end

    def to_webform
      clauses.collect { |c| c.to_webform }.flatten
    end
  end
end
