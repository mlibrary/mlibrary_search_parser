require_relative 'spec_helper'

RSpec.describe "PreQueryNestedFieldsParser" do
  before do
    @config_file = './spec/data/00-catalog.yml'
    @config = YAML.load(ERB.new(File.read(@config_file)).result)
    @fieldnames               = @config["search_fields"].keys.sort { |a, b| b.size <=> a.size }
    @parser = MLibrarySearchParser::PreQueryNestedFieldsParser.new(@fieldnames)
  end

  it "validates a single field" do
    expect { @parser.parse("title:test") }.not_to raise_error
  end

  it "validates sequential fields" do
    expect { @parser.parse("title:test author:word") }.not_to raise_error
  end

  it "validates sequential fields inside parens" do
    expect { @parser.parse("(title:test author:word)") }.not_to raise_error
  end

  it "validates fields on either side of a binary operator inside parens" do
    expect { @parser.parse("(title:test OR author:word)") }.not_to raise_error
  end

  it "validates fields on either side of a binary operator" do
    expect { @parser.parse("title:test OR author:word") }.not_to raise_error
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

  it "ignores nested parens with no field" do
    expect { @parser.parse("(one (two) three)") }.not_to raise_error
  end
end
