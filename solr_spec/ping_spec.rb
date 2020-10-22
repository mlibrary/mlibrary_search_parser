# frozen_string_literal: true

require 'solr_wrapper'
require 'simple_solr_client'
require 'pry-byebug'
require_relative 'ssc_client_monkeypatch'

RSpec.describe "ping" do
  it "can see solr" do
    SolrWrapper.wrap do |solr|
      SOLR_INSTANCE_DIR = solr.instance_dir
      # binding.pry
      client = SimpleSolrClient::Client.new(solr.url)
      client.new_core('test_core') unless client.cores.include?('test_core')
      core = client.core('test_core')
      expect(core.up?).to be true
    end
  end
end
