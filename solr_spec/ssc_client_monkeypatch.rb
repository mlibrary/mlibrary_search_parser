require "securerandom"

module SimpleSolrClient
  class Client
    # Set up files for a temp core
    def temp_core_dir_setup(corename)
      dest = Dir.mktmpdir("simple_solr_#{corename}_#{SecureRandom.uuid}", File.join(SOLR_INSTANCE_DIR, "/server/solr"))
      src = SAMPLE_CORE_DIR
      FileUtils.cp_r File.join(src, "."), dest
      dest
    end
  end
end

module SimpleSolrClient::Core::Search
  def fv_search(field, value)
    v = value
    v = SimpleSolrClient.lucene_escape Array(value).join(" ") unless v == "*"
    kv = "#{field}:(#{v})"
    get("select", {q: kv, rows: 50}, SimpleSolrClient::Response::QueryResponse)
  end
end
