# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "FieldedNode" do
  before do
    tokens = tnode("some terms")
    @node  = MLibrarySearchParser::Node::FieldedNode.new("title", tokens)
  end

  it "has to_s" do
    expect(@node.to_s).to eq "title:(some terms)"
  end

  it "has a simple to_clean_string" do
    expect(fielded_node('title', 'one').to_clean_string).to eq("title:one")
  end

  it "has multi-term to_clean_string" do
    expect(@node.to_clean_string).to eq("title:(some terms)")
  end

  it "has a more complex to_clean_string" do
    n = and_node(fielded_node('title', and_node('one', 'two')), fielded_node("author", '"phrase here"'))
    expect(n.to_clean_string).to eq('title:(one AND two) AND author:("phrase here")')
  end

  it "has to_webform" do
    expect(@node.to_webform).to eq([
                                     {"field" => "title"},
                                     {"query" => "some terms"}
                                   ])
  end

  describe "Equality and traversing" do
    it "implements ==" do
      n1 = and_node(fielded_node('title', 'one'), fielded_node('author', 'two'))
      n2 = and_node(fielded_node('title', 'one'), fielded_node('author', 'two'))
      n3 = and_node(fielded_node('title', 'one'), fielded_node('author', 'XXXXXXX'))

      expect(n1).to eq(n2)
      expect(n2).to_not eq(n3)
    end

    it "can deep-dup" do
      n1 = and_node(fielded_node('title', or_node('one', 'two')), "three")
      expect(n1.dup).to eq(n1)
    end
  end
end
