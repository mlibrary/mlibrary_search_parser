# frozen_string_literal: true

# array of {field: blah, query: blah, booleanType: blah}
# where booleanType is an index into [AND, OR, NOT]

require 'spec_helper'

RSpec.describe "AdvancedSearch" do

  it "accepts a single field" do
    @config_file = './spec/data/00-catalog.yml'
    @config = YAML.load(ERB.new(File.read(@config_file)).result)
    builder = MLibrarySearchParser::AdvancedSearchBuilder.new(@config)
    search = builder.build([{field: "author", query: "twain", booleanType: 0}])
    expect(search.to_s).to eq("author:(twain)")
  end

end