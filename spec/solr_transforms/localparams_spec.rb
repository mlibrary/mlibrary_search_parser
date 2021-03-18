require_relative '../spec_helper'
require 'mlibrary_search_parser/transform/solr/local_params'


# Build up a localparams object based on the given search string

def localparams(str)
  search = catalog_search(str)
  MLibrarySearchParser::Transformer::Solr::LocalParams.new(search)
end

RSpec.describe MLibrarySearchParser::Transformer::Solr::LocalParams do

  describe "Correctly use mm with/without booleans" do
    it "adds mm for non-boolean search" do
      lp = localparams("one two")
      expect(lp.query).to match(/mm=\$default_mm/)
    end

    it "doesn't add mm for boolean search" do
      lp = localparams("one AND two")
      expect(lp.query).to_not match(/mm=\$default_mm/)
    end
  end

end