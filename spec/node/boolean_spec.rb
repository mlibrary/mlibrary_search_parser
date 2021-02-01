# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "BooleanNode" do
  before do
    @left       = MLibrarySearchParser::Node::TokensNode.new("left terms")
    @right      = MLibrarySearchParser::Node::TokensNode.new("right terms")
    @genericAnd = and_node("left", "right right")
    @genericOr  = or_node("left left", "right")
    @complex    = and_node(or_node('one', 'two'), or_node('three', not_node('four')))
  end


  describe "Generic and AND Boolean node" do
    before do
      @node = MLibrarySearchParser::Node::AndNode.new(@left, @right)
    end

    it "has to_s" do
      expect(@node.to_s).to eq "(left terms) AND (right terms)"
    end

    it "produces a clean string with multi terms" do
      expect(@node.clean_string).to eq("(left terms) AND (right terms)")
    end

    it "produces a clean string with single terms" do
      expect(@genericAnd.clean_string).to eq("left AND (right right)")
    end

    it "has two children" do
      expect(@node.children).to match_array [@left, @right]
    end

    it "flattens" do
      expect(@node.flatten).to match_array [@left, @node, @right]
    end

    it "gets tokens" do
      expect(@node.tokens_string).to eq("left terms right terms")
    end

    it "implements equality" do
      expect(@node).to eq(@node)
    end

    it "implements equality for different instances with the same data" do
      string = "one two three"
      expect(tnode(string)).to eq(tnode(string))
    end


    it "gets the 'positive' clauses" do
      node = MLibrarySearchParser::Node::AndNode.new(tnode('one'), not_node('two'))
      expect(node.positives).to match_array([tnode('one')])
    end

    it "gets the 'negative' clauses" do
      node = MLibrarySearchParser::Node::AndNode.new(tnode('one'), not_node('two'))
      pp(node)
      expect(node.negatives).to match_array([tnode('two')])
    end
  end

  describe "OrNode" do
    before do
      @node = or_node("left terms", "right terms")
    end

    it "has to_s" do
      expect(@node.to_s).to eq "(left terms) OR (right terms)"
    end

    describe "Nested" do
      before do
        not_node   = MLibrarySearchParser::Node::NotNode.new(MLibrarySearchParser::Node::TokensNode.new("unwanted terms"))
        @nest_node = MLibrarySearchParser::Node::AndNode.new(@node, not_node)
      end

      it "to_s" do
        expect(@nest_node.to_s).to eq "((left terms) OR (right terms)) AND (NOT (unwanted terms))"
      end

      it "provides equality for trees of booleans" do
        node_1 = and_node(or_node("one two", "three four"),
                          and_node("five six", "seven"))
        node_2 = and_node(or_node("one two", "three four"),
                          and_node("five six", "seven"))

        expect(node_1).to eq(node_2)
      end

      it "doesn't show equality for unequal content" do
        b1 = and_node("one", "two")
        b2 = or_node("three", "four")
        b3 = and_node("five", "six")
        b4 = and_node(or_node("one two", "three four"),
                      and_node("five six", "seven"))
        b5 = and_node(or_node("one two", "three four"),
                      and_node("five six", "XXXXXXX"))
        expect(b1).to_not eq(b2)
        expect(b4).to_not eq(b5)
      end

      it "shows equality for deep_dup" do
        dup = @complex.deep_dup
        expect(@complex).to eq(dup)
      end

      it "does deep dup with a block" do
        dup = @complex.deep_dup do |n|
          if n.is_type?(:tokens)
            tnode('X')
          else
            n
          end
        end
        expect(dup.tokens_string).to eq 'X X X X'
      end
    end

  end

end
