require_relative 'spec_helper'

RSpec.describe "PreQueryDoubleQuotesParser" do
  before do
    @parser = MLibrarySearchParser::PreQueryDoubleQuotesParser.new
  end

  it "validates balanced double quotes" do
    expect { @parser.parse("\"test\"") }.not_to raise_error
  end

  it "validates an arbitrary even number of quotes" do
    expect { @parser.parse("t\"e \"sst tes\"\"") }.not_to raise_error
  end

  it "fails on an unmatched quote" do
    expect { @parser.parse("\"") }.to raise_error(Parslet::ParseFailed)
  end

  it "fails on an odd number of quotes" do
    expect { @parser.parse("\"test\"\" thing") }.to raise_error(Parslet::ParseFailed)
  end
end
