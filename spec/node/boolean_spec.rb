# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "BooleanNode" do
  before do
    @left       = MLibrarySearchParser::Node::TokensNode.new("left terms")
    @right      = MLibrarySearchParser::Node::TokensNode.new("right terms")
    @genericAnd = and_node("left", "right right")
    @genericOr  = or_node("left left", "right")
    @complex = and_node(or_node('one', 'two'), or_node('three', not_node('four')))
  end


  describe "AndNode" do
    before do
      @node = MLibrarySearchParser::Node::AndNode.new(@left, @right)
    end

    it "has to_s" do
      expect(@node.to_s).to eq "(left terms) AND (right terms)"
    end

    it "has to_webform" do
      expect(@node.to_webform).to eq([
                                         {"query" => "left terms"},
                                         {"operator" => "AND"},
                                         {"query" => "right terms"}
                                     ])
    end

    it "produces a clean string with multi terms" do
      expect(@node.to_clean_string).to eq("(left terms) AND (right terms)")
    end

    it "produces a clean string with single terms" do
      expect(@genericAnd.to_clean_string).to eq("left AND (right right)")
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
    
    it "implement equality" do
      expect(@node).to eq(@node)
    end
    
    it "implements equality for different instances" do
      string = "one two three"
      expect(tnode(string)).to eq(tnode(string))
    end


  end

  describe "OrNode" do
    before do
      @node = or_node("left terms", "right terms")
    end

    it "has to_s" do
      expect(@node.to_s).to eq "(left terms) OR (right terms)"
    end

    it "has to_webform" do
      expect(@node.to_webform).to eq([
                                         {"query" => "left terms"},
                                         {"operator" => "OR"},
                                         {"query" => "right terms"}
                                     ])
    end

    describe "Nested" do
      before do
        not_node   = MLibrarySearchParser::Node::NotNode.new(MLibrarySearchParser::Node::TokensNode.new("unwanted terms"))
        @nest_node = MLibrarySearchParser::Node::AndNode.new(@node, not_node)
      end

      it "to_s" do
        expect(@nest_node.to_s).to eq "((left terms) OR (right terms)) AND (NOT (unwanted terms))"
      end

      it "to_webform" do
        expect(@nest_node.to_webform).to eq([
                                                {"query" => "left terms"},
                                                {"operator" => "OR"},
                                                {"query" => "right terms"},
                                                {"operator" => "AND"},
                                                {"operator" => "NOT"},
                                                {"query" => "unwanted terms"}
                                            ])
      end
    end

  end

end
