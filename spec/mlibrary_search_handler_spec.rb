RSpec.describe "MLibrarySearchHandler" do
  before do
    @handler = MLibrarySearchParser::SearchHandler.new
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
   

  end
end
