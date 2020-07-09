RSpec.describe "PreQueryNestedFieldsParser" do
  before do
    @parser = MLibrarySearchParser::PreQueryNestedFieldsParser.new
  end

  it "validates a single field" do
    parsed = @parser.parse("title:test")
    pp parsed
  end

  it "validates sequential fields" do
    parsed = @parser.parse("title:test author:word")
    pp parsed
  end

  it "validates fields with parens in them" do
    parsed = @parser.parse("title:(test word) author:thing")
    pp parsed
  end

  it "rejects a field containing a field in parens" do
    expect {
      parsed = @parser.parse("title:(thing author:test)")
      pp parsed
    }.to raise_error(Parslet::ParseFailed)
  end
end
