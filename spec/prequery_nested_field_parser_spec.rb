RSpec.describe "PreQueryNestedFieldsParser" do
  before do
    @parser = MLibrarySearchParser::PreQueryNestedFieldsParser.new('spec/fields_file.json')
  end

  it "validates a single field" do
    expect { @parser.parse("title:test") }.not_to raise_error
  end

  it "validates sequential fields" do
    expect { @parser.parse("title:test author:word") }.not_to raise_error
  end

  it "validates fields with parens in them" do
    expect { @parser.parse("title:(test word) author:thing") }.not_to raise_error
  end

  it "rejects a field containing a field in parens" do
    expect { @parser.parse("title:(thing author:test)") }.to raise_error(Parslet::ParseFailed)
  end

  it "rejects a field containing a field in parens differently" do
    expect { @parser.parse("title:(author:test)") }.to raise_error(Parslet::ParseFailed)
  end

  it "doesn't recognize a nested field" do
    parsed = @parser.parse("title:author:huck finn")
    expect(parsed[0]).not_to have_key(:fielded)
    expect(parsed[0]).to have_key(:tokens)
  end

end
