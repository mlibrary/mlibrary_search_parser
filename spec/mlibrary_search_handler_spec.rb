RSpec.describe "MLibrarySearchHandler" do
  before do
    @handler = MLibrarySearchParser::SearchHandler.new('spec/fields_file.json')
  end

  describe "pre_process" do
    it "returns a simple search" do
      output = @handler.pre_process("a search")
      expect(output).to eq "a search"
    end

    it "removes unbalanced parentheses" do
      output = @handler.pre_process("a ((search)")
      expect(output).to eq "a search"
    end

    it "removes unbalanced double quotes" do
      output = @handler.pre_process("a \"\"search\"")
      expect(output).to eq "a search"
    end

    it "leaves balanced parentheses" do
      output = @handler.pre_process("a (search)()")
      expect(output).to eq "a (search)()"
    end

    it "leaves balanced double quotes" do
      output = @handler.pre_process("\"a \"search\"\"")
      expect(output).to eq "\"a \"search\"\""
    end

    it "removes immediately-nested fields" do
      output = @handler.pre_process("title:author:blah")
      expect(output).to eq "title:author blah"
    end

    it "removes fields nested in parentheses" do
      output = @handler.pre_process("title:(thing author:blah")
      expect(output).to eq "title:thing author:blah"
    end

    it "removes fields differently nested in parentheses" do
      output = @handler.pre_process("title:(author:thing)")
      expect(output).to eq "title:author thing"
    end
   
    it "ignores things that look like nested fields but aren't" do
      output = @handler.pre_process("title:one:author")
      expect(output).to eq "title:one:author"
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
