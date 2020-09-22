module MLibrarySearchParser::Node
  class BaseNode
    include Enumerable
    attr_accessor :parent
    def set_parent!(parent)
      @parent = parent
      self
    end

    def tokens_node?
      false
    end

    def boolean_node?
      false
    end

    def and_node?
      false
    end

    def or_node?
      false
    end

    def not_node?
      false
    end

    def fielded_node?
      false
    end

    def unparseable_node?
      false
    end

    def multi_clause_node?
      false
    end

    def root_node?
      self.parent.nil?
    end

    def children
      []
    end

    def descendants
      children.flat_map(&:flatten)
    end

    # def each
    #   return enum_for(:each) unless block_given?
    #   descendants.each {|x| yield x}
    # end

    def flatten
      descendants.unshift(self)
    end

    def contains_fielded?
      self.any?{|x| x.fielded_node?}
    end

    def ancestors
      if self.root_node?
        []
      else
        [parent].concat parent.ancestors
      end
    end

    def in_fielded?
      ancestors.any? {|x| x.fielded_node }
    end

  end

  class TokensNode < BaseNode
    attr_accessor :text
    def initialize(text)
      @text = text.to_s
    end

    def tokens_node?
      true
    end

    def children
      []
    end

    def to_s
      text
    end

    def inspect
      "<TokensNode: [#{text}]>"
    end

    def to_webform
      {"query" => text}
    end
  end

  class UnparseableNode < TokensNode
    def inspect
      "<UnparseableNode: [#{text}]>"
    end

    def unparseable_node?
      true
    end

    def children
      []
    end
  end
end
