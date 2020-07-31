RSpec.describe "Node" do
  describe "BaseNode" do
    it "has a parent" do
      node_1 = MLibrarySearchParser::Node::BaseNode.new
      node_2 = MLibrarySearchParser::Node::BaseNode.new
      node_1.set_parent!(node_2)
      expect(node_1.parent).to eq node_2
    end
  end

  describe "UnparseableNode" do
    before do
      @node = MLibrarySearchParser::Node::UnparseableNode.new("title:something AND blah")
    end

    it "has to_s" do
      expect(@node.to_s).to eq "title:something AND blah"
    end

    it "has to_webform" do
      expect(@node.to_s).to eq "title:something AND blah"
    end
  end

  describe "TokensNode" do
    before do
      @node = MLibrarySearchParser::Node::TokensNode.new("some text")
    end

    it "has text" do
      expect(@node.text).to eq "some text"
    end

    it "returns that text for to_s" do
      expect(@node.to_s).to eq "some text"
    end

    it "returns that text for to_webform" do
      expect(@node.to_webform).to eq({"query" => "some text"})
    end
  end

  describe "BooleanNode" do
    before do
      @left = MLibrarySearchParser::Node::TokensNode.new("left terms")
      @right = MLibrarySearchParser::Node::TokensNode.new("right terms")
    end

    describe "AndNode" do
      before do
        @node = MLibrarySearchParser::Node::AndNode.new(@left, @right)
      end

      it "has to_s" do
        expect(@node.to_s).to eq "(left terms) AND (right terms)"
      end

      it "has to_webform" do
        expect(@node.to_webform).to eq([ 
          {"query" => "left terms"},
          {"operator" => "AND"},
          {"query" => "right terms"}
          ])
      end
    end

    describe "OrNode" do
      before do
        @node = MLibrarySearchParser::Node::OrNode.new(@left, @right)
      end

      it "has to_s" do
        expect(@node.to_s).to eq "(left terms) OR (right terms)"
      end

      it "has to_webform" do
        expect(@node.to_webform).to eq([ 
          {"query" => "left terms"},
          {"operator" => "OR"},
          {"query" => "right terms"}
          ])
      end

      describe "Nested" do
        before do
          not_node = MLibrarySearchParser::Node::NotNode.new(MLibrarySearchParser::Node::TokensNode.new("unwanted terms"))
          @nest_node = MLibrarySearchParser::Node::AndNode.new(@node, not_node)
        end

        it "to_s" do
          expect(@nest_node.to_s).to eq "((left terms) OR (right terms)) AND (NOT (unwanted terms))"
        end

        it "to_webform" do
          expect(@nest_node.to_webform).to eq([
            {"query" => "left terms"},
            {"operator" => "OR"},
            {"query" => "right terms"},
            {"operator" => "AND"},
            {"operator" => "NOT"},
            {"query" => "unwanted terms"}
          ])
        end
      end
  
    end

  end

  describe "UnaryNode" do
    before do
      @node = MLibrarySearchParser::Node::NotNode.new(MLibrarySearchParser::Node::TokensNode.new("something"))
    end

    it "has to_s" do
      expect(@node.to_s).to eq "NOT (something)"
    end

    it "has to_webform" do
      expect(@node.to_webform).to eq([{"operator" => "NOT"},
        {"query" => "something"}])
    end
  end
  
  describe "FieldedNode" do
    before do
      tokens = MLibrarySearchParser::Node::TokensNode.new("some terms")
      @node = MLibrarySearchParser::Node::FieldedNode.new("title", tokens)
    end

    it "has to_s" do
      expect(@node.to_s).to eq "title:(some terms)"
    end

    it "has to_webform" do
      expect(@node.to_webform).to eq([
        {"field" => "title"},
        {"query" => "some terms"}
      ])
    end
  end
end
