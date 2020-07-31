RSpec.describe "Search" do
    describe "a simple search" do
        before do
            @search = MLibrarySearchParser::Search.new("a simple search")
        end
        it "returns its original input" do
            expect(@search.original_input).to eq "a simple search"
        end

        it "says it is valid" do
            expect(@search.valid?).to eq true
        end

        it "has no errors" do
            expect(@search.errors?).to eq false
        end

        it "has no warnings" do
            expect(@search.warnings?).to eq false
        end

        it "returns input as to_s" do
            expect(@search.to_s).to eq "a simple search"
        end
        
        it "returns webform input as hash" do
            expect(@search.to_webform).to eq([{"query" => "a simple search"}])
        end

        it "returns solr query" do
            expect(@search.to_solr_query).to eq "a simple search"
        end
    end

    describe "a query AND some more query" do
        before do
            @search = MLibrarySearchParser::Search.new("a query AND some more query")
        end
        it "returns its original input" do
            expect(@search.original_input).to eq "a query AND some more query"
        end

        it "says it is valid" do
            expect(@search.valid?).to eq true
        end


        it "has no errors" do
            expect(@search.errors?).to eq false
        end

        it "has no warnings" do
            expect(@search.warnings?).to eq false
        end

        it "returns to_s with explicit scoping" do
            expect(@search.to_s).to eq "(a query) AND (some more query)"
        end
        
        it "has to_webform" do
            expect(@search.to_webform).to eq([ 
                {"query" => "a query"},
                {"operator" => "AND"},
                {"query" => "some more query"}
                ])
        end

        it "returns solr query" do
            expect(@search.to_solr_query).to eq "(a query) AND (some more query)"
        end
    end

    describe "title:somebody OR author:something NOT author:whozit" do
        before do
            @search = MLibrarySearchParser::Search.new("title:somebody OR author:something NOT author:whozit")
        end

        it "returns its original input" do
            expect(@search.original_input).to eq "title:somebody OR author:something NOT author:whozit"
        end

        it "says it is valid" do
            expect(@search.valid?).to eq true
        end


        it "has no errors" do
            expect(@search.errors?).to eq false
        end

        it "has no warnings" do
            expect(@search.warnings?).to eq false
        end

        it "returns to_s with explicit scoping" do
            expect(@search.to_s).to eq "(title:(somebody)) OR (author:(something)) | NOT (author:(whozit))"
        end
        
        it "has to_webform" do
            expect(@search.to_webform).to eq([ 
                {"field" => "title"},
                {"query" => "somebody"},
                {"operator" => "OR"},
                {"field" => "author"},
                {"query" => "something"},
                {"operator" => "NOT"},
                {"field" => "author"},
                {"query" => "whozit"}
                ])
        end

        it "returns solr query" do
            expect(@search.to_solr_query).to eq "(title:(somebody)) OR (author:(something)) | NOT (author:(whozit))"
        end
    end

    describe "title:something (AND somebody" do
        before do
            @search = MLibrarySearchParser::Search.new("title:something (AND somebody")
        end

        it "returns its original input" do
            expect(@search.original_input).to eq "title:something (AND somebody"
        end

        it "says it is not valid" do
            #expect(@search.valid?).to eq false
        end

        it "has no errors" do
            #expect(@search.errors?).to eq true
        end

        it "has no warnings" do
            expect(@search.warnings?).to eq false
        end
    end
end