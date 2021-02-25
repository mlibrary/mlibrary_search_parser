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
        attr_accessor :transform, :params, :query, :search_tree, :original_search_tree, :config

        # @param [MLibrarySearchParser::Search] search
        def initialize(search)
          @original_search_tree = search
          @search_tree          = lucene_escape_node(search.search_tree.deep_dup)
          @search_tree.renumber!
          @params = {}
          @query  = {}
          @config = search.config
          transform!
        end

        def transform!
          if ['', '*'].include? @original_search_tree.clean_string.strip
            set_param('q', '*:*')
          else
            @query = transform(search_tree)
          end
        end

        def solr_params
          @config['solr_params'] || {}
        end

        def default_field
          @config["search_field_default"]
        end

        def default_attributes
          @config['search_attr_defaults'] || {}
        end

        def field_config(field)
          @config['search_fields'][field]
        end

        # Set params, symbolizing the keys on the way in
        def set_param(key, value)
          params[key.to_sym] = value
        end

        # Dispatch to specific methods for transforming
        # each node type
        # @param [MLibrarySearchParser::Node::BaseNode] node
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
          when :unparseable
            unparseable_node(node)
          else
            raise ArgumentError, "Unknown node type #{node.node_type}"
          end
        end


        def tokens_node(node)
          edismaxify(default_field, node)
        end

        def and_node(node)
          if node.contains_fielded?
            boolnode(node, :must)
          else
            edismaxify(default_field, node)
          end
        end

        def or_node(node)
          if node.contains_fielded?
            boolnode(node, :should)
          else
            edismaxify(default_field, node)
          end
        end

        def fielded_node(node)
          edismaxify(node.field, node.query)
        end

        def reduce_ands(clauses)
          if clauses.size == 1
            clauses.first
          else
            MLibrarySearchParser::Node::AndNode.new(clauses.first, reduce_ands(clauses[1..-1]))
          end
        end


        def search_node(node)
          if node.clauses.size == 1
            transform(node.clauses.first)
          else
            boolnode(reduce_ands(node.clauses), :must)
          end
        end

        def unparseable_node(node)
          tok = MLibrarySearchParser::Node::TokensNode.new(node.clean_string.downcase)
          tok.renumber!
          edismaxify(default_field, tok)
        end

      end
    end
  end
end

