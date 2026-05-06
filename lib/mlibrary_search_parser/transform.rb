module MLibrarySearchParser
  module Transformer
    # Base module for all transformers
  end
end

require_relative "transform/base"
require_relative "transform/solr/json_edismax"
require_relative "transform/solr/local_params"
require_relative "transform/solr/solr_search"
require_relative "transform/solr/utilities"
require_relative "transform/opensearch/query_dsl"
