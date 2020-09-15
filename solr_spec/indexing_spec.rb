require 'solr_wrapper'
require 'simple_solr_client'
require 'pry-byebug'
require_relative 'ssc_client_monkeypatch'
require_relative 'test_solr_docs'

RSpec.describe "indexing" do
  it "finds the right docs when searching" do
    SolrWrapper.wrap do |solr|
      SOLR_INSTANCE_DIR = solr.instance_dir
      client = SimpleSolrClient::Client.new(solr.url)
      client.new_core('test_core') unless client.cores.include?('test_core')
      core = client.core('test_core')
      # binding.pry
      core.add_docs(TestDocs::DOCS)
      core.commit
      expect(core.number_of_documents).to eq 45
      # search title:(huck finn)
      # find 19, 22
      # do not find 1, 21, 37
      found = core.fv_search(:title_t, "huck finn")
      found_ids = found.docs.collect { |d| d.id }
      expect(found_ids).to include("19", "22")
      expect(found_ids).not_to include("1", "24")
    end
  end
end