# frozen_string_literal: true

require_relative 'json_edismax'
require 'mlibrary_search_parser/search'
module MLibrarySearchParser
  module Transformer
    module Solr
      # A solr search object is a dumb data container for two sets of things:
      #   * URL arguments relevant to this search to be sent in a POST or GET
      #   * An (optional, sometimes ignored) hash to send (as json) to the
      #    [JSON request API](https://lucene.apache.org/solr/guide/8_5/json-request-api.html)
      class SolrSearch
        attr_accessor :transform, :params, :payload

        # @param [MLibrarySearchParser::Se]
        # @param [MLibrarySearchParser::Transformer::Solr::JsonEdismax] transformer
        def initialize(query, transformer)
          @query = query.deep_d
          @transformer = transformer
          @params  = Hash.new({})
          @payload = {}
          @config = transformer.config
        end

        # We can't use a hash to represent params because they can be repeated
        def add_param(key, value)
          params[key] << value
        end

        def replace_param(key, value)
          params[key] = [value]
        end

      end
    end
  end
end

