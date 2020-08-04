RSpec.describe "WebformParser" do
    it "parses a simple search" do
        form = [{"query" => "a simple search"}]
        parsed = MLibrarySearchParser::WebformParser.new(form)
        expect(parsed.to_s).to eq "a simple search"
    end

    it "parses a boolean" do
        form = [{"query" => "a query"},
                {"operator" => "AND"},
                {"query" => "some more query"}]
        parsed = MLibrarySearchParser::WebformParser.new(form)
        expect(parsed.to_s).to eq "a query AND some more query"
    end

    it "parses a field" do
        form = [{"field" => "title"},
            {"query" => "something"}]
        parsed = MLibrarySearchParser::WebformParser.new(form)
        expect(parsed.to_s).to eq "title:something"
    end

    it "builds search tree from a field" do
        form = [{"fielded" => {"field" => "title",
            "query" => "something AND something else"}}]
        parsed = MLibrarySearchParser::WebformParser.new(form)
        expect(parsed.to_tree_s).to eq "title:((something) AND (something else))"
    end

    it "builds search tree from a boolean" do
        form = [{"fielded" => {"field" => "title", "query" => "something AND something else"}},
            {"operator" => "OR"},
            {"fielded" => {"field" => "author", "query" => "somebody"}}]
        parsed = MLibrarySearchParser::WebformParser.new(form)
        expect(parsed.to_tree_s).to eq "(title:((something) AND (something else))) OR (author:(somebody))"
    end

    it "parses something complicated" do
        form = [ 
            {"field" => "title"},
            {"query" => "somebody"},
            {"operator" => "OR"},
            {"field" => "author"},
            {"query" => "something"},
            {"operator" => "NOT"},
            {"field" => "author"},
            {"query" => "whozit"}
            ]
        parsed = MLibrarySearchParser::WebformParser.new(form)
        expect(parsed.to_s).to eq "title:somebody OR author:something NOT author:whozit"
    end
end