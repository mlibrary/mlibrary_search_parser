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
      @text = text.to_s
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
end
