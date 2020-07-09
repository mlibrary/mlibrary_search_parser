RSpec.describe MLibrarySearchParser do
  it "has a version number" do
    expect(MLibrarySearchParser::VERSION).not_to be nil
  end

  before(:example) do
    @parser = MLibrarySearchParser::QueryParser.new
    @transformer = MLibrarySearchParser::QueryTransformer.new
  end

  it "returns a plain search" do
    parsed = @parser.parse("A search")
    expect(@transformer.apply(parsed).to_s).to eq "A search"
  end

  it "ignores lower-case and" do
    parsed = @parser.parse("mark twain and huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "mark twain and huck finn"
  end

  it "demarcates AND left/right scopes" do
    parsed = @parser.parse("mark twain AND huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "(mark twain) AND (huck finn)"
  end

  it "ignores lower-case or" do
    parsed = @parser.parse("mark twain or huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "mark twain or huck finn"
  end

  it "demarcates OR left/right scopes" do
    parsed = @parser.parse("mark twain OR huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "(mark twain) OR (huck finn)"
  end

  it "keeps NOT" do
    parsed = @parser.parse("mark twain NOT huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "mark twain | NOT (huck finn)"
  end

  it "ignores not" do
    parsed = @parser.parse("mark twain not huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "mark twain not huck finn"
  end

  it "handles OR followed by AND" do
    parsed = @parser.parse("mark twain OR samuel clemens AND huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "(mark twain) OR ((samuel clemens) AND (huck finn))"
  end

  it "handles AND followed by OR" do
    parsed = @parser.parse("mark twain AND samuel clemens OR huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "((mark twain) AND (samuel clemens)) OR (huck finn)"
  end

  it "ignores AND in double quotes" do
    parsed = @parser.parse("mark \"twain AND clemens\"")
    expect(@transformer.apply(parsed).to_s).to eq "mark \"twain AND clemens\""
  end

  it "uses the first of sequential AND OR" do
    parsed = @parser.parse("mark twain AND OR huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "(mark twain) AND (huck finn)"
  end

  it "uses the first of sequential OR AND" do
    parsed = @parser.parse("mark twain OR AND huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "(mark twain) OR (huck finn)"
  end

  it "accepts sequence AND NOT" do
    parsed = @parser.parse("mark twain AND NOT huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "(mark twain) AND (NOT (huck finn))"
  end

  it "preserves provided parens" do
    parsed = @parser.parse("(mark twain OR samuel clemens) AND huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "((mark twain) OR (samuel clemens)) AND (huck finn)"
  end

  it "doesn't allow a fielded in tokens" do
    expect{@parser.tokens.parse("one two title:three four")}.to raise_error(Parslet::ParseFailed)
  end

  it "picks up a title field" do
    parsed = @parser.parse("title:huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "title:(huck finn)"
  end

  it "allows fields on both sides of AND" do
    parsed = @parser.parse("author:mark twain AND title:huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "(author:(mark twain)) AND (title:(huck finn))"
  end

  it "allows sequential fieldeds" do
    parsed = @parser.parse("title:tom sawyer title:huck finn")
    expect(@transformer.apply(parsed).to_s).to eq "title:(tom sawyer) | title:(huck finn)"
  end

  it "allows a boolean within fielded" do
    parsed = @parser.parse("author:(mark twain AND samuel clemens)")
    expect(@transformer.apply(parsed).to_s).to eq "author:((mark twain) AND (samuel clemens))"
  end

  it "allows bare words before a fielded" do
    parsed = @parser.parse("huck finn author:mark twain")
    expect(@transformer.apply(parsed).to_s).to eq "huck finn | author:(mark twain)"
  end
end
