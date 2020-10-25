# frozen_string_literal: true

require_relative 'json_edismax'
require 'mlibrary_search_parser/search'
require 'mlibrary_search_parser/transform/solr/utilities'

module MLibrarySearchParser
  module Transformer
    module Solr
      # A solr search object is a dumb data container for two sets of things:
      #   * URL arguments relevant to this search to be sent in a POST or GET
      #   * An (optional, sometimes ignored) hash to send (as json) to the
      #    [JSON request API](https://lucene.apache.org/solr/guide/8_5/json-request-api.html)
      class SolrSearch
        include Utilities
        attr_accessor :transform, :params, :payload

        # @param [MLibrarySearchParser::Search] search
        # @param [MLibrarySearchParser::Transformer::Solr::JsonEdismax] transformer
        def initialize(search)
          @query       = lucene_escape_node(search.search_tree)
          @params      = Hash.new({})
          @payload     = {}
          @config      = search.config
        end

        # We can't use a hash to represent params because they can be repeated
        def add_param(key, value)
          params[key] << value
        end

        def replace_param(key, value)
          params[key] = [value]
        end

        # Dispatch to specific methods for transforming
        # each node type
        # @param [MLibrarySearchParser::Node::BaseNode] node
        # @param [MLibrarySearchParser::Transform::SolrSearch] ss
        # @return [??] depends on that transformation being done
        def transform(node)
          case node.node_type
          when :tokens
            tokens_node(node)
          when :fielded
            fielded_node(node)
          when :search
            search_node(node)
          when :and
            and_node(node)
          when :or
            or_node(node)
          when :not
            not_node(node)
          else
            raise ArgumentError, "Unknown node type #{node.node_type}"
          end
        end


        def tokens_node(node)
          edismaxify(node)
        end

        def and_node(node)
          if node.contains_fielded?
            boolnode(node, :must)
          else
            edismaxify(node)
          end
        end

        def or_node(node)
          if node.contains_fielded?
            boolnode(node, :should)
          else
            edismaxify(node)
          end
        end

        def fielded_node(node)
          edismaxify(node)
        end

        def search_node(node, extras: {})
          if node.clauses.size == 1
            transform(node.clauses.first)
          else
            boolnode(node, :must)
          end
        end

      end
    end
  end
end

