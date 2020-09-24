module MLibrarySearchParser::Node
  class BaseNode
    include Enumerable
    attr_accessor :parent
    def set_parent!(parent)
      @parent = parent
      self
    end

    def parenthesize_multiwords(s)
      if s.match(/\s/) and !s.match(/\A\(.*\)\Z/)
        "(#{s})"
      else
        s
      end
    end

    def to_clean_string
      parenthesize_multiwords(to_s)
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

    def tokens
      self.flatten.map {|x| x.tokens_node? ? x.to_s : nil }.compact
    end

    def tokens_string
      tokens.join(" ")
    end

    def tokens_phrase
      %Q["#{tokens_string.gsub('"', '')}"]
    end

    alias_method :qq, :tokens_phrase


  end

  class TokensNode < BaseNode
    attr_accessor :text
    def initialize(text)
      @text = text.to_s
    end

    def node_type
      :tokens
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

    def node_type
      :unparseable
    end

    def unparseable_node?
      true
    end

    def children
      []
    end
  end
end
