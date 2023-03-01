# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SearchNode" do
  before do
    @simple = search_node("one")
    @fielded = search_node(fielded_node("title", "two"))
    @simple_multi = search_node("one", "two", "three")
    @complex = search_node(and_node("one", "two"), or_node("three", "four"))
    @complex_dup = search_node(and_node("one", "two"), or_node("three", "four"))
  end

  describe "Basics" do
    it "stringifies" do
      expect(@simple.clean_string).to eq "one"
      expect(@fielded.clean_string).to eq "title:two"
      expect(@simple_multi.clean_string).to eq "one two three"
      expect(@complex.clean_string).to eq "(one AND two) (three OR four)"
    end

    it "provides equality" do
      expect(@complex).to eq(@complex_dup)
    end

    it "deep_dups" do
      expect(@complex.deep_dup).to eq(@complex_dup)
    end

    it "deep_dups with a block" do
      dup = @complex.deep_dup { |n| n.is_type?(:or) ? tnode("XXX") : n }
      expect(dup.clean_string).to eq "(one AND two) XXX"
    end

    it "finds wanted tokens" do
      neg = search_node(and_node("one", or_node(not_node(tnode("two")), tnode("three"))))
      expect(neg.wanted_tokens_string).to eq "one three"
    end

    it "finds wanted tokens in a more complex search" do
      s = catalog_search("one AND author:(two NOT three) OR four NOT five")
      expect(s.wanted_tokens_string).to eq("one two four")
    end

    it "produces a tree string" do
      expect(@fielded.tree_string).to eq "FIELD: title\n  ┝  two"
      expect(@complex.tree_string).to eq "AND\n  ┝  one\n  ┝  two\nOR\n  ┝  three\n  ┝  four"
    end
  end
end
