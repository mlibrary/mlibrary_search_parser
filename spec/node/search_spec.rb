# frozen_string_literal: true

require 'spec_helper'


RSpec.describe "SearchNode" do

  before do
    @simple       = search_node("one")
    @fielded      = search_node(fielded_node('title', 'two'))
    @simple_multi = search_node("one", "two", "three")
    @complex      = search_node(and_node('one', 'two'), or_node('three', 'four'))
    @complex_dup  = search_node(and_node('one', 'two'), or_node('three', 'four'))
  end

  describe "Basics" do
    it "stringifies" do
      expect(@simple.to_clean_string).to eq "one"
      expect(@fielded.to_clean_string).to eq "title:two"
      expect(@simple_multi.to_clean_string).to eq "one two three"
      expect(@complex.to_clean_string).to eq "(one AND two) (three OR four)"
    end

    it "provides equality" do
      expect(@complex).to eq(@complex_dup)
    end

    it "deep_dups" do
      expect(@complex.deep_dup).to eq(@complex_dup)
    end

    it "deep_dups with a block" do
      dup = @complex.deep_dup {|n| n.is_type?(:or) ? tnode("XXX") : n }
      expect(dup.to_clean_string).to eq "(one AND two) XXX"
    end

  end

end
