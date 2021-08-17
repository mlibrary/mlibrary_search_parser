# frozen_string_literal: true
require 'spec_helper'
require "mlibrary_search_parser/node"

RSpec.describe "Unparseable and Empty nodes" do
  describe "UnparseableNode" do
    before do
      @node = MLibrarySearchParser::Node::UnparseableNode.new("title:something AND blah")
    end

    it "has to_s" do
      expect(@node.to_s).to eq "title:something AND blah"
    end
  end

  describe "EmptyNode" do
    before do
      @node = MLibrarySearchParser::Node::EmptyNode.new
    end

    it "has to_s" do
      expect(@node.to_s).to eq("")
    end

    it "raises if you try to give it text" do
      expect { MLibrarySearchParser::Node::EmptyNode.new("junk") }.to raise_error(ArgumentError)
    end
  end
end
