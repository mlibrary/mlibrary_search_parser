require_relative 'spec_helper'
require 'mlibrary_search_parser/query_parser'

RSpec.describe MLibrarySearchParser do
  it "has a version number" do
    expect(MLibrarySearchParser::VERSION).not_to be nil
  end

  before do
    @config_file = './spec/data/00-catalog.yml'
    @config      = YAML.load(ERB.new(File.read(@config_file)).result)
    @fieldnames  = @config["search_fields"].keys.sort { |a, b| b.size <=> a.size }
    @parser      = MLibrarySearchParser::QueryParser.new(@fieldnames)
    @transformer = MLibrarySearchParser::QueryTransformer.new

    def parse_and_transform(string)
      parsed = @parser.parse(string)
      @transformer.apply(parsed)
    end
  end

  it "returns a plain search" do
    expect(parse_and_transform("A search").inspect).to eq "<TokensNode: [A search]>"
  end

  it "ignores lower-case and" do
    expect(parse_and_transform("mark twain and huck finn").to_s).to eq "mark twain and huck finn"
  end

  it "demarcates AND left/right scopes" do
    expect(parse_and_transform("mark twain AND huck finn").to_s).to eq "(mark twain) AND (huck finn)"
  end

  it "ignores lower-case or" do
    expect(parse_and_transform("mark twain or huck finn").to_s).to eq "mark twain or huck finn"
  end

  it "demarcates OR left/right scopes" do
    expect(parse_and_transform("mark twain OR huck finn").to_s).to eq "(mark twain) OR (huck finn)"
  end

  it "ignores lower-case not" do
    expect(parse_and_transform("mark twain not huck finn").to_s).to eq "mark twain not huck finn"
  end

  it "demarcates NOT right scope" do
    expect(parse_and_transform("NOT huck finn").to_s).to eq "NOT (huck finn)"
  end

  it "allows query parts before NOT" do
    expect(parse_and_transform("mark twain NOT huck finn").to_s).to eq "mark twain | NOT (huck finn)"
  end

  it "handles OR followed by AND" do
    expect(parse_and_transform("mark twain OR samuel clemens AND huck finn").to_s).to eq "(mark twain) OR ((samuel clemens) AND (huck finn))"
  end

  it "handles AND followed by OR" do
    expect(parse_and_transform("mark twain AND samuel clemens OR huck finn").to_s).to eq "((mark twain) AND (samuel clemens)) OR (huck finn)"
  end

  it "ignores AND in double quotes" do
    expect(parse_and_transform("mark \"twain AND clemens\"").to_s).to eq "mark \"twain AND clemens\""
  end

  it "uses the first of sequential AND OR" do
    expect(parse_and_transform("mark twain AND OR huck finn").to_s).to eq "(mark twain) AND (huck finn)"
  end

  it "uses the first of sequential OR AND" do
    expect(parse_and_transform("mark twain OR AND huck finn").to_s).to eq "(mark twain) OR (huck finn)"
  end

  it "accepts sequence AND NOT" do
    expect(parse_and_transform("mark twain AND NOT huck finn").to_s).to eq "(mark twain) AND (NOT (huck finn))"
  end

  it "allows parens to override normal precedence" do
    expect(parse_and_transform("(mark twain OR samuel clemens) AND huck finn").to_s).to eq "((mark twain) OR (samuel clemens)) AND (huck finn)"
  end

  it "doesn't allow a fielded in tokens" do
    expect { @parser.tokens.parse("one two title:three four") }.to raise_error(Parslet::ParseFailed)
  end

  it "picks up a title field" do
    expect(parse_and_transform("title:huck finn").to_s).to eq "title:(huck finn)"
  end

  it "allows fields on both sides of AND" do
    expect(parse_and_transform("author:mark twain AND title:huck finn").to_s).to eq "(author:(mark twain)) AND (title:(huck finn))"
  end

  it "allows sequential fieldeds" do
    expect(parse_and_transform("title:tom sawyer title:huck finn").to_s).to eq "title:(tom sawyer) | title:(huck finn)"
  end

  it "allows a boolean within fielded" do
    expect(parse_and_transform("author:(mark twain AND samuel clemens)").to_s).to eq "author:((mark twain) AND (samuel clemens))"
  end

  it "allows bare words before a fielded" do
    expect(parse_and_transform("huck finn author:mark twain").to_s).to eq "huck finn | author:(mark twain)"
  end

  it "allows bare words before and after fielded in parens" do
    expect(parse_and_transform("huck finn author:(mark twain) tom sawyer").to_s).to eq "huck finn | author:(mark twain) | tom sawyer"
  end

  it "ignores field names with no colon" do
    expect(parse_and_transform("author huck finn").to_s).to eq "author huck finn"
  end

  it "doesn't pick up words preceding colons that are not field names" do
    expect(parse_and_transform("random:huck finn").to_s).to eq "random:huck finn"
  end

  it "does something reasonable with embedded colons" do
    expect(parse_and_transform("title:one:author").to_s).to eq "title:(one:author)"
  end

  it "doesn't pick up a fieldname with a space after the colon" do
    expect(parse_and_transform("author: huck finn").to_s).to eq "author: huck finn"
  end

  it "doesn't mind if there's no space after an ending double quote" do
    expect(parse_and_transform('"my name"bill').to_s).to eq '"my name" | bill'
  end

  it "does something with empty parens" do
    expect(parse_and_transform('something ()').to_s).to eq 'something | '
  end

  it "handles consecutive fieldeds" do
    expect(parse_and_transform('author:one title:two').to_s).to eq("author:(one) | title:(two)")
  end

  it 'works with multiple clauses in parens of a boolean' do
    expect(parse_and_transform('bill AND (author:one title:two)').to_s).to eq("(bill) AND (author:(one) | title:(two))")
  end

  it 'works with a multi-clause thing inside a multi-clause thing' do
    expect(parse_and_transform('(one title:two (three AND (four author:five)))').to_s).to eq 'one | title:(two) | (three) AND (four | author:(five))'
  end

  it "handles two clauses before an OR" do
    expect(parse_and_transform("one author:mark twain OR two").to_s).to eq "one | (author:(mark twain)) OR (two)"
  end

  it "handles two clauses before an AND" do
    expect(parse_and_transform("one author:mark twain OR two").to_s).to eq "one | (author:(mark twain)) OR (two)"
  end

  it "parses a lone NOT after another clause" do
    expect(parse_and_transform("one NOT two").to_s).to eq "one | NOT (two)"
  end

  it "parses a lone NOT after another clause in parens" do
    expect(parse_and_transform("three AND (one NOT two)").to_s).to eq "(three) AND (one | NOT (two))"

  end

  it "parses a lone NOT after another clause in a fielded" do
    expect(parse_and_transform("title:(one NOT two)").to_s).to eq "title:(one | NOT (two))"
  end

  it "deals with fielded in parens" do
    str = '(title:jones OR author:smith)'
    expect(parse_and_transform(str).clean_string).to eq str
  end

  # The following all don't parse (inspired by spreadsheet "NOT sawyer (finn AND twain)")
  #   * NOT sawyer (finn AND twain)
  #   * NOT one (two)
  #   * NOT (one) (two)
  #   * one NOT two (three)
  #   * NOT one two (three)
  #   * NOT one (NOT two)
  # ...but these are fine
  #   * NOT one two
  #   * NOT one two AND three
  #   * one NOT (two three)
  #   * one NOT two three
  it "allows NOT with clause(s) followed by parenthesized clause" do
    str = "NOT one (two)"
    expect(parse_and_transform(str).clean_string).to eq "(NOT (one)) two"
  end

  it "as above but fully parenthesized" do
    str = "(NOT one (two))"
    expect(parse_and_transform(str).clean_string).to eq "(NOT (one)) two"
  end

  it "allows parenthesized clause following AND NOT clause" do
    str = "one AND NOT one (two)"
    expect(parse_and_transform(str).clean_string).to eq "(one AND (NOT (one))) two"
  end

  it "treats parentheses with only tokens inside as part of tokens" do
    str = "subject:Moscow (Russia) History"
    parsed = @parser.parse(str)
    pp parsed
    parse_and_transform_value = @transformer.apply(parsed)
    expect(parse_and_transform_value.to_s).to eq "subject:(Moscow (Russia) History)"
  end

end
