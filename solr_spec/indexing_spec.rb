require "solr_wrapper"
require "simple_solr_client"
require "pry-byebug"
require_relative "ssc_client_monkeypatch"
require_relative "test_solr_docs"

def add_copy_field(client)
  client.post_json("test_core/schema",
    {"add-field": {
      name: "allfields",
      type: "text_general",
      indexed: true,
      stored: true,
      multiValued: true
    }})
  client.post_json("test_core/schema",
    {"add-copy-field": {
      source: "*_t",
      dest: ["allfields"]
    }})
end

def assert_search_results(core, field, value, should_include, should_not_include)
  found = core.fv_search(field, value)
  found_ids = found.docs.collect { |d| d.id }
  expect(found_ids).to include(*should_include)
  expect(found_ids).not_to include(*should_not_include)
end

RSpec.describe "indexing" do
  it "finds the right docs when searching" do
    SolrWrapper.wrap do |solr|
      SOLR_INSTANCE_DIR = solr.instance_dir
      client = SimpleSolrClient::Client.new(solr.url)
      if client.cores.include?("test_core")
        client.core("test_core").clear.commit.unload
      end
      core = client.new_core("test_core")
      add_copy_field(client)
      core.add_docs(TestDocs::DOCS).commit
      expect(core.number_of_documents).to eq 45
      # search title:(huck finn)
      # find 19, 22
      # do not find 1, 21, 37
      assert_search_results(core, :title_t, "huck finn", ["19", "22"], ["1", "24"])
    end
  end
end
