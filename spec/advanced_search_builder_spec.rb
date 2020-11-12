# frozen_string_literal: true

# array of {field: blah, query: blah, booleanType: blah}
# where booleanType is an index into [AND, OR, NOT]

require 'spec_helper'

RSpec.describe "AdvancedSearch" do

  before do
    @config_file = './spec/data/00-catalog.yml'
    @config = YAML.load(ERB.new(File.read(@config_file)).result)
    @builder = MLibrarySearchParser::AdvancedSearchBuilder.new(@config)
  end

  it "accepts a single field" do
    search = @builder.build([{field: "author", query: "twain", booleanType: 0}])
    expect(search.to_s).to eq("author:(twain)")
  end

  it "accepts two fields" do
    search = @builder.build([
        {field: "author", query: "twain", booleanType: 0},
        {field: "title", query: "finn", booleanType: 1}
                            ])
    expect(search.to_s).to eq("(author:(twain)) AND (title:(finn))")
  end

end