# frozen_string_literal: true

# array of {field: blah, query: blah, booleanType: blah}
# where booleanType is an index into [AND, OR, NOT]

require 'spec_helper'

RSpec.describe "AdvancedSearch" do

  before do
    @parser = MLibrarySearchParser::AdvancedSearchParser.new
  end

  it "accepts a single field" do
    parsed = @parser.parse([{field: "author", query: "twain", booleanType: 0}])
    expect(parsed).to eq("author:twain")
  end

  it "accepts two fields" do
    parsed = @parser.parse([
                                {field: "author", query: "twain", booleanType: 0},
                                {field: "title", query: "finn", booleanType: 1}
                            ])
    expect(parsed).to eq("author:twain AND title:finn")
  end

  it "accepts three fields" do
    parsed = @parser.parse([
        {field: "author", query: "twain", booleanType: 2},
        {field: "title", query: "finn", booleanType: 1},
        {field: "subject", query: "America", booleanType: 0}
                           ])
    expect(parsed).to eq("author:twain NOT title:finn OR subject:America")
  end
end