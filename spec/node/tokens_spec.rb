# frozen_string_literal: true

require 'spec_helper'
require "mlibrary_search_parser/node/tokens"

RSpec.describe "TokensNode" do
  before do
    @node = MLibrarySearchParser::Node::TokensNode.new("some text")
  end

  it "has text" do
    expect(@node.text).to eq "some text"
  end

  it "returns that text for to_s" do
    expect(@node.to_s).to eq "some text"
  end

  it "returns that text for to_webform" do
    expect(@node.to_webform).to eq({"query" => "some text"})
  end

  it "parenthesizes multiple words" do
    expect(@node.to_clean_string).to eq "(some text)"
  end

  it "recognizes equality of itself" do
    expect(@node).to eq(@node)
  end

  it "implements equality" do
    expect(tnode("one")).to eq(tnode('one'))
  end
end
