# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe "SpecialCharReplacer" do
  before do
    @parser = MLibrarySearchParser::SpecialCharParser.new
    @transformer = MLibrarySearchParser::SpecialCharTransformer.new
  end

  it "replaces smart underscore" do
    parsed = @parser.parse("‗")
    out = @transformer.apply(parsed)
    expect(out).to eq "_"
  end

  it "replaces smart comma" do
    parsed = @parser.parse("‚")
    out = @transformer.apply(parsed)
    expect(out).to eq ','
  end

  it "replaces smart dash" do
    parsed = @parser.parse("– — ―")
    out = @transformer.apply(parsed)
    expect(out).to eq "- - -"
  end

  it "replaces smart single quote" do
    parsed = @parser.parse("‘ ’ ‛ ′")
    out = @transformer.apply(parsed)
    expect(out).to eq "' ' ' '"
  end

  it "replaces smart double quote" do
    parsed = @parser.parse('“ ” „ ″ ‟')
    out = @transformer.apply(parsed)
    expect(out).to eq '" " " " "'
  end
end
