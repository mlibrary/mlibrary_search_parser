RSpec.describe "MLibrarySearchHandler" do
  before do
    @handler = MLibrarySearchParser::SearchHandler.new('spec/data/fields_file.json')
  end

  describe "pre_process" do
    it "returns a simple search" do
      output = @handler.pre_process("a search")
      expect(output.to_s).to eq "a search"
      expect(output.errors).to be_empty
    end

    it "removes unbalanced parentheses" do
      output = @handler.pre_process("a ((search)")
      expect(output.to_s).to eq "a search"
      expect(output.errors).to match_array([MLibrarySearchParser::UnevenParensError])
    end

    it "removes unbalanced double quotes" do
      output = @handler.pre_process("a \"\"search\"")
      expect(output.to_s).to eq "a search"
      expect(output.errors).to match_array([MLibrarySearchParser::UnevenQuotesError])
    end

    it "leaves balanced parentheses" do
      output = @handler.pre_process("a (search)(a)")
      expect(output.to_s).to eq "a (search)(a)"
      expect(output.errors).to be_empty
    end

    it "leaves balanced double quotes" do
      output = @handler.pre_process('"a "search"a"')
      expect(output.to_s).to eq '"a "search"a"'
      expect(output.errors).to be_empty
    end

    it "removes immediately-nested fields" do
      output = @handler.pre_process("title:author:blah")
      expect(output.to_s).to eq "title:author blah"
      expect(output.errors).to match_array([MLibrarySearchParser::NestedFieldsError])
    end

    it "removes fields nested in parentheses" do
      output = @handler.pre_process("title:(thing author:blah)")
      expect(output.to_s).to eq "title:thing author:blah"
      expect(output.errors).to match_array([MLibrarySearchParser::NestedFieldsError])
    end

    it "removes fields differently nested in parentheses" do
      output = @handler.pre_process("title:(author:thing)")
      expect(output.to_s).to eq "title:author thing"
      expect(output.errors).to match_array([
        MLibrarySearchParser::NestedFieldsError,
        MLibrarySearchParser::NestedFieldsError
      ])
    end
   
    it "ignores things that look like nested fields but aren't" do
      output = @handler.pre_process("title:one:author")
      expect(output.to_s).to eq "title:one:author"
      expect(output.errors).to be_empty
    end
  end

  describe "parse" do
    it "returns our custom search tree" do
      output = @handler.parse("title:huck finn AND author:mark twain")
      expect(output.class).to eq MLibrarySearchParser::Node::SearchNode
      expect(output.to_s).to eq "(title:(huck finn)) AND (author:(mark twain))"
    end
  end
end
