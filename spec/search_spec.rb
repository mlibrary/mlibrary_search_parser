require_relative "spec_helper"

RSpec.describe "Search" do
  describe "a simple search" do
    before do
      @config_file = "./spec/data/00-catalog.yml"
      @config = YAML.load(ERB.new(File.read(@config_file)).result)
      @search = MLibrarySearchParser::Search.new("a simple search", @config)
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

    it "returns solr query" do
      expect(@search.to_solr_query).to eq "a simple search"
    end

    it "constructs a factory" do
      search_builder = MLibrarySearchParser::Search.search_builder(@config)
      search = search_builder.build("a simple search")
      expect(search.to_s).to eq("a simple search")
    end
  end

  describe "a query AND some more query" do
    before do
      @config_file = "./spec/data/00-catalog.yml"
      @config = YAML.load(ERB.new(File.read(@config_file)).result)
      @search = MLibrarySearchParser::Search.new("a query AND some more query", @config)
    end
    it "returns its original input" do
      expect(@search.original_input).to eq "a query AND some more query"
    end

    it "returns to_s with explicit scoping" do
      expect(@search.to_s).to eq "(a query) AND (some more query)"
    end

    it "returns solr query" do
      expect(@search.to_solr_query).to eq "(a query) AND (some more query)"
    end
  end

  describe "title:somebody OR author:something NOT author:whozit" do
    before do
      @config_file = "./spec/data/00-catalog.yml"
      @config = YAML.load(ERB.new(File.read(@config_file)).result)
      @search = MLibrarySearchParser::Search.new("title:somebody OR author:something NOT author:whozit", @config)
    end

    it "returns its original input" do
      expect(@search.original_input).to eq "title:somebody OR author:something NOT author:whozit"
    end

    it "returns to_s with explicit scoping" do
      expect(@search.to_s).to eq "(title:(somebody)) OR (author:(something)) | NOT (author:(whozit))"
    end

    it "returns solr query" do
      expect(@search.to_solr_query).to eq "(title:(somebody)) OR (author:(something)) | NOT (author:(whozit))"
    end
  end

  describe "title:something (AND somebody" do
    before do
      @config_file = "./spec/data/00-catalog.yml"
      @config = YAML.load(ERB.new(File.read(@config_file)).result)
      @search = MLibrarySearchParser::Search.new("title:something (AND somebody", @config)
    end

    it "returns its original input" do
      expect(@search.original_input).to eq "title:something (AND somebody"
    end

    it "says it is not valid" do
      expect(@search.valid?).to eq false
    end

    it "has errors" do
      expect(@search.errors?).to eq true
      expect(@search.errors).to match_array [MLibrarySearchParser::UnevenParensError]
    end

    it "gives a reasonable clean string" do
      expect(@search.clean_string).to eq "(title:something AND somebody)"
    end
  end

  describe "Testing failures from spreadsheet" do
    before do
      @config_file = "./spec/data/00-catalog.yml"
      @config = YAML.load(ERB.new(File.read(@config_file)).result)
      @builder = MLibrarySearchParser::SearchBuilder.new(@config)
    end

    it "(title:jones OR author:smith)" do
      str = "(title:jones OR author:smith)"
      search = @builder.build(str)
      expect(search.valid?).to be_truthy
    end
  end
end
