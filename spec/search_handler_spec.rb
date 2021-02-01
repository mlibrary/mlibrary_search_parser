require_relative 'spec_helper'

RSpec.describe "MLibrarySearchHandler" do
  before do
    @config_file = './spec/data/00-catalog.yml'
    @config = YAML.load(ERB.new(File.read(@config_file)).result)
    @handler = MLibrarySearchParser::SearchHandler.new(@config)
  end

  describe "check_quotes" do
    it "removes unbalanced double quotes" do
      search = MLibrarySearchParser::MiniSearch.new("a \"\"search\"")
      output = @handler.check_quotes(search)
      expect(output.to_s).to eq "a search"
      expect(output.errors).to match_array([MLibrarySearchParser::UnevenQuotesError])
    end

    it "leaves balanced double quotes" do
      search = MLibrarySearchParser::MiniSearch.new('"a "search"a"')
      output = @handler.check_quotes(search)
      expect(output.to_s).to eq '"a "search"a"'
      expect(output.errors).to be_empty
    end
  end

  describe "check_parens" do
    it "removes unbalanced parentheses" do
      search = MLibrarySearchParser::MiniSearch.new("a ((search)")
      output = @handler.check_parens(search)
      expect(output.to_s).to eq "a search"
      expect(output.errors).to match_array([MLibrarySearchParser::UnevenParensError])
    end

    it "leaves balanced parentheses" do
      search = MLibrarySearchParser::MiniSearch.new("a (search)(a)")
      output = @handler.check_parens(search)
      expect(output.to_s).to eq "a (search)(a)"
      expect(output.errors).to be_empty
    end
  end

  describe "check_nested_fields" do
    it "removes immediately-nested fields" do
      search = MLibrarySearchParser::MiniSearch.new("title:author:blah")
      output = @handler.check_nested_fields(search)
      expect(output.to_s).to eq "title:author blah"
      expect(output.errors).to match_array([MLibrarySearchParser::NestedFieldsError])
    end

    it "removes fields nested in parentheses" do
      search = MLibrarySearchParser::MiniSearch.new("title:(thing author:blah)")
      output = @handler.check_nested_fields(search)
      expect(output.to_s).to eq "title:thing author:blah"
      expect(output.errors).to match_array([MLibrarySearchParser::NestedFieldsError])
    end

    it "removes fields differently nested in parentheses" do
      search = MLibrarySearchParser::MiniSearch.new("title:(author:thing)")
      output = @handler.check_nested_fields(search)
      expect(output.to_s).to eq "title:author thing"
      expect(output.errors).to match_array([
        MLibrarySearchParser::NestedFieldsError,
        MLibrarySearchParser::NestedFieldsError
      ])
    end
   
    it "ignores things that look like nested fields but aren't" do
      search = MLibrarySearchParser::MiniSearch.new("title:one:author")
      output = @handler.check_nested_fields(search)
      expect(output.to_s).to eq "title:one:author"
      expect(output.errors).to be_empty
    end

    it "ignores things that would be nested fields except they're in double-quotes" do
      search = MLibrarySearchParser::MiniSearch.new('title:(something "author:subject")')
      output = @handler.check_nested_fields(search)
      expect(output.to_s).to eq 'title:(something "author:subject")'
      expect(output.errors).to be_empty
    end
  end

  describe "check parse" do
    it "catches an error when something will break the parser" do
      search = MLibrarySearchParser::MiniSearch.new("something with (unbalanced parens")
      output = @handler.check_parse(search)
      expect(output.to_s).to eq "something with (unbalanced parens"
      expect(output.errors).to match_array([MLibrarySearchParser::UnparseableError])
    end
  end

  describe "pre_process" do
    it "returns a simple search" do
      search = MLibrarySearchParser::MiniSearch.new("a search")
      output = @handler.pre_process(search)
      expect(output.to_s).to eq "a search"
      expect(output.errors).to be_empty
    end

    it "fixes special characters" do
      search = MLibrarySearchParser::MiniSearch.new('a “search”')
      output = @handler.pre_process(search)
      expect(output.to_s).to eq 'a "search"'
      expect(output.errors).to be_empty
    end

    it "collects multiple errors where applicable" do
      search = MLibrarySearchParser::MiniSearch.new('test) "with title:(author:many problems)')
      output = @handler.pre_process(search)
      expect(output.to_s).to eq "test with title:author many problems"
      expect(output.errors).to match_array([
        MLibrarySearchParser::UnevenQuotesError,
        MLibrarySearchParser::UnevenParensError,
        MLibrarySearchParser::NestedFieldsError
      ])
    end
  end

  describe "parse" do
    it "returns expected string" do
      output = @handler.parse("title:huck finn AND author:mark twain")
      expect(output.to_s).to eq "(title:(huck finn)) AND (author:(mark twain))"
    end

    it "returns something useful even on a parser error" do
      output = @handler.parse("title:somebody(")
      expect(output.to_s).to eq("title:somebody(")
    end
  end
end
