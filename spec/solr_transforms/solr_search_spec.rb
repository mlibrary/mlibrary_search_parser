require_relative '../spec_helper'
require 'mlibrary_search_parser/transform/solr/local_params'

# Build up a localparams object based on the given search string

def solr_search(str)
  search = catalog_search(str)
  MLibrarySearchParser::Transformer::Solr::SolrSearch.new(search)
end

RSpec.describe MLibrarySearchParser::Transformer::Solr::SolrSearch do

  it "handles the single-asterisk search" do
    lp = solr_search("*")
    expect(lp.params[:q]).to eq("*:*")
  end

end