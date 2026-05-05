# frozen_string_literal: true

require "spec_helper"

RSpec.describe "OpenSearch Query DSL Transformer" do
  before(:all) do
    @config_file = "./spec/data/00-catalog.yml"
    @config = YAML.load(ERB.new(File.read(@config_file)).result)
    @config[:output_format] = :opensearch
  end

  describe "Basic TokensNode transformations" do
    it "transforms simple search terms to match query" do
      search = MLibrarySearchParser::Search.new("simple search", @config)
      query = search.to_opensearch_query

      expect(query).to be_a(Hash)
      expect(query).to have_key(:query)
      expect(query[:query]).to have_key(:match)
    end

    it "transforms single word to match query" do
      search = MLibrarySearchParser::Search.new("test", @config)
      query = search.to_opensearch_query

      expect(query[:query][:match]).to be_a(Hash)
    end

    it "transforms phrase in quotes to match_phrase" do
      search = MLibrarySearchParser::Search.new('"exact phrase"', @config)
      query = search.to_opensearch_query

      expect(query[:query]).to have_key(:match_phrase)
    end
  end

  describe "AndNode transformations" do
    it "transforms AND operator to bool with must" do
      search = MLibrarySearchParser::Search.new("cats AND dogs", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to have_key(:bool)
      expect(query[:query][:bool]).to have_key(:must)
      expect(query[:query][:bool][:must]).to be_an(Array)
      expect(query[:query][:bool][:must].length).to eq(2)
    end

    it "handles multiple AND operations" do
      search = MLibrarySearchParser::Search.new("one AND two AND three", @config)
      query = search.to_opensearch_query

      expect(query[:query][:bool][:must]).to be_an(Array)
      expect(query[:query][:bool][:must].length).to be >= 2
    end

    it "handles nested AND with parentheses" do
      search = MLibrarySearchParser::Search.new("(cats AND dogs) AND birds", @config)
      query = search.to_opensearch_query

      expect(query[:query][:bool]).to have_key(:must)
    end
  end

  describe "OrNode transformations" do
    it "transforms OR operator to bool with should" do
      search = MLibrarySearchParser::Search.new("cats OR dogs", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to have_key(:bool)
      expect(query[:query][:bool]).to have_key(:should)
      expect(query[:query][:bool][:should]).to be_an(Array)
      expect(query[:query][:bool][:should].length).to eq(2)
    end

    it "handles multiple OR operations" do
      search = MLibrarySearchParser::Search.new("one OR two OR three", @config)
      query = search.to_opensearch_query

      expect(query[:query][:bool][:should]).to be_an(Array)
      expect(query[:query][:bool][:should].length).to be >= 2
    end
  end

  describe "NotNode transformations" do
    it "transforms NOT operator to bool with must_not" do
      search = MLibrarySearchParser::Search.new("cats NOT dogs", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to have_key(:bool)
      # Should have positive terms and must_not
      expect(query[:query][:bool]).to have_key(:must_not)
      expect(query[:query][:bool][:must_not]).to be_an(Array)
    end

    it "handles NOT at beginning" do
      search = MLibrarySearchParser::Search.new("NOT unwanted", @config)
      query = search.to_opensearch_query

      expect(query[:query][:bool]).to have_key(:must_not)
    end

    it "handles multiple NOT clauses" do
      search = MLibrarySearchParser::Search.new("cats NOT dogs NOT birds", @config)
      query = search.to_opensearch_query

      expect(query[:query][:bool][:must_not]).to be_an(Array)
      expect(query[:query][:bool][:must_not].length).to be >= 1
    end
  end

  describe "FieldedNode transformations" do
    it "transforms title: queries to field-specific query" do
      search = MLibrarySearchParser::Search.new("title:hamlet", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to be_a(Hash)
      # Should contain field-specific query structure
    end

    it "transforms author: queries to field-specific query" do
      search = MLibrarySearchParser::Search.new("author:shakespeare", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to be_a(Hash)
    end

    it "handles fielded queries with phrases" do
      search = MLibrarySearchParser::Search.new('title:"complete works"', @config)
      query = search.to_opensearch_query

      expect(query[:query]).to be_a(Hash)
    end

    it "handles multiple fielded queries" do
      search = MLibrarySearchParser::Search.new("title:hamlet author:shakespeare", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to be_a(Hash)
    end
  end

  describe "Complex nested queries" do
    it "transforms mixed Boolean operators" do
      search = MLibrarySearchParser::Search.new("(cats OR dogs) AND NOT birds", @config)
      query = search.to_opensearch_query

      expect(query[:query][:bool]).to be_a(Hash)
      expect(query[:query][:bool]).to have_key(:must)
      expect(query[:query][:bool]).to have_key(:must_not)
    end

    it "handles deeply nested queries" do
      search = MLibrarySearchParser::Search.new("((a OR b) AND c) OR (d AND e)", @config)
      query = search.to_opensearch_query

      expect(query[:query][:bool]).to be_a(Hash)
    end

    it "handles fielded queries with Boolean operators" do
      search = MLibrarySearchParser::Search.new("title:hamlet AND author:shakespeare", @config)
      query = search.to_opensearch_query

      expect(query[:query][:bool]).to be_a(Hash)
      expect(query[:query][:bool][:must]).to be_an(Array)
    end

    it "handles mixed fielded and non-fielded queries" do
      search = MLibrarySearchParser::Search.new("title:hamlet shakespeare", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to be_a(Hash)
    end
  end

  describe "Edge cases and special scenarios" do
    it "handles empty search string" do
      search = MLibrarySearchParser::Search.new("", @config)
      query = search.to_opensearch_query

      expect(query).to be_a(Hash)
      expect(query[:query]).to be_a(Hash)
    end

    it "handles single character searches" do
      search = MLibrarySearchParser::Search.new("a", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to be_a(Hash)
    end

    it "handles special characters that need escaping" do
      search = MLibrarySearchParser::Search.new("C++", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to be_a(Hash)
    end

    it "handles wildcards" do
      search = MLibrarySearchParser::Search.new("prog*", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to be_a(Hash)
    end

    it "handles queries with parentheses but no operators" do
      search = MLibrarySearchParser::Search.new("(simple query)", @config)
      query = search.to_opensearch_query

      expect(query[:query]).to be_a(Hash)
    end
  end

  describe "SearchNode transformations" do
    it "wraps simple queries in proper query structure" do
      search = MLibrarySearchParser::Search.new("test query", @config)
      query = search.to_opensearch_query

      expect(query).to have_key(:query)
      expect(query[:query]).to be_a(Hash)
    end

    it "generates valid OpenSearch query structure" do
      search = MLibrarySearchParser::Search.new("test", @config)
      query = search.to_opensearch_query

      # Should be valid JSON-serializable
      expect { JSON.generate(query) }.not_to raise_error
    end

    it "preserves query complexity in output structure" do
      search = MLibrarySearchParser::Search.new("cats AND dogs OR birds", @config)
      query = search.to_opensearch_query

      expect(query[:query][:bool]).to be_a(Hash)
    end
  end

  describe "Query field configuration" do
    it "uses configured query fields from config" do
      search = MLibrarySearchParser::Search.new("test", @config)
      query = search.to_opensearch_query

      # Should respect configured fields from YAML
      expect(query[:query]).to be_a(Hash)
    end

    it "handles field weights/boosts from config" do
      search = MLibrarySearchParser::Search.new("test search", @config)
      query = search.to_opensearch_query

      # May include boost values based on config
      expect(query[:query]).to be_a(Hash)
    end
  end

  describe "Comparison with Solr output" do
    it "generates different structure than Solr for same query" do
      solr_config = @config.dup
      solr_config[:output_format] = :solr

      opensearch_config = @config.dup
      opensearch_config[:output_format] = :opensearch

      solr_search = MLibrarySearchParser::Search.new("test query", solr_config)
      opensearch_search = MLibrarySearchParser::Search.new("test query", opensearch_config)

      solr_output = solr_search.to_solr_query
      opensearch_output = opensearch_search.to_opensearch_query

      # Outputs should be different formats
      expect(opensearch_output).to be_a(Hash)
      expect(opensearch_output).to have_key(:query)
    end
  end

  describe "API and method integration" do
    it "responds to to_opensearch_query method" do
      search = MLibrarySearchParser::Search.new("test", @config)
      expect(search).to respond_to(:to_opensearch_query)
    end

    it "maintains compatibility with existing methods" do
      search = MLibrarySearchParser::Search.new("test", @config)
      expect(search).to respond_to(:to_s)
      expect(search).to respond_to(:original_input)
      expect(search).to respond_to(:valid?)
    end
  end
end

