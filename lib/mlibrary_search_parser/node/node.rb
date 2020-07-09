module MLibrarySearchParser::Node
  class BaseNode
    attr_accessor :parent
    def set_parent!(parent)
      @parent = parent
      self
    end
  end

  class TokensNode < BaseNode
    attr_accessor :text
    def initialize(text)
      @text = text
    end

    def to_s
      text
    end
  end
end
