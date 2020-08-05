RSpec.describe "WebformParser" do
    it "parses a field" do
        form = [{"fielded" => {"field" => "title",
            "query" => "something AND something else"}}]
        parsed = MLibrarySearchParser::WebformParser.new(form)
        expect(parsed.to_s).to eq "title:((something) AND (something else))"
    end

    it "parses a boolean" do
        form = [{"fielded" => {"field" => "title", "query" => "something AND something else"}},
            {"operator" => "OR"},
            {"fielded" => {"field" => "author", "query" => "somebody"}}]
        parsed = MLibrarySearchParser::WebformParser.new(form)
        expect(parsed.to_s).to eq "(title:((something) AND (something else))) OR (author:(somebody))"
    end

    it "nests sequential booleans top-down" do
        form = [ {"fielded" => {"field" => "title", "query" => "somebody"}},
            {"operator" => "OR"},
            {"fielded" => {"field" => "author", "query" => "something"}},
            {"operator" => "AND"},
            {"fielded" => {"field" => "editor", "query" => "whozit"}}
            ]
        parsed = MLibrarySearchParser::WebformParser.new(form)
        expect(parsed.to_s).to eq "((title:(somebody)) OR (author:(something))) AND (editor:(whozit))"
    end

    it "parses a NOT as AND NOT" do
        form = [ {"fielded" => {"field" => "title", "query" => "somebody"}},
            {"operator" => "OR"},
            {"fielded" => {"field" => "author", "query" => "something"}},
            {"operator" => "NOT"},
            {"fielded" => {"field" => "editor", "query" => "whozit"}},
            {"operator" => "AND"},
            {"fielded" => {"field" => "allfields", "query" => "whatsit"}}
            ]
        parsed = MLibrarySearchParser::WebformParser.new(form)
        expect(parsed.to_s).to eq "(((title:(somebody)) OR (author:(something))) AND (NOT (editor:(whozit)))) AND (allfields:(whatsit))"
    end
end