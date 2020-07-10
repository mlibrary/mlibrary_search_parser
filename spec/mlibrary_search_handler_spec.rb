RSpec.describe "MLibrarySearchHandler" do
  before do
    @handler = MLibrarySearchParser::SearchHandler.new
  end

  it "returns a simple search" do
    output = @handler.process("a search")
    expect(output).to eq "a search"
  end
end
