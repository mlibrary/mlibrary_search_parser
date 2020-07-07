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
    expect(@transformer.apply(parsed)).to eq "A search"
  end

  it "ignores lower-case and" do
    parsed = @parser.parse("mark twain and huck finn")
    expect(@transformer.apply(parsed)).to eq "mark twain and huck finn"
  end

  it "demarcates AND left/right scopes" do
    parsed = @parser.parse("mark twain AND huck finn")
    expect(@transformer.apply(parsed)).to eq "(mark twain) AND (huck finn)"
  end

  it "ignores lower-case or" do
    parsed = @parser.parse("mark twain or huck finn")
    expect(@transformer.apply(parsed)).to eq "mark twain or huck finn"
  end

  it "demarcates OR left/right scopes" do
    parsed = @parser.parse("mark twain OR huck finn")
    expect(@transformer.apply(parsed)).to eq "(mark twain) OR (huck finn)"
  end
end
