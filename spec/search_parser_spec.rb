require 'rspec'
require_relative 'spec_helper'

RSpec.describe 'SearchParser' do

  before do
    @config_file = './spec/data/00-catalog.yml'
    @config = YAML.load(ERB.new(File.read(@config_file)).result)
    @mirlyn_parser = MLibrarySearchParser::SearchParser.new(@config["fields"])
  end

  it 'creates a Search object' do
    search = @mirlyn_parser.parse("a search")
    expect(search).to_not be_nil
  end

  it "does the right thing" do
    search = @mirlyn_parser.parse("title:one two AND author:three")
    expect(search.to_clean_string).to eq "(title:(one two) AND author:three)"
    expect(search.warnings).to be_empty
  end

end