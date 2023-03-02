# frozen_string_literal: true

require_relative "json_edismax"
require "mlibrary_search_parser/search"
require "mlibrary_search_parser/transform/solr/utilities"

module MLibrarySearchParser
  module Transformer
    module Solr
      # A solr search object is a dumb data container for two sets of things:
      #   * URL arguments relevant to this search to be sent in a POST or GET
      #   * An (optional, sometimes ignored) hash to send (as json) to the
      #    [JSON request API](https://lucene.apache.org/solr/guide/8_5/json-request-api.html)
      class SolrSearch
        include Utilities
        attr_accessor :params, :query, :search_tree, :original_search_tree, :config

        # @param [MLibrarySearchParser::Search] search
        def initialize(search)
          @original_search_tree = search.shake
          @search_tree = lucene_escape_node(search.search_tree.deep_dup)
          @search_tree.renumber!
          @params = {}
          @query = {}
          @config = search.config
          transform!
        end

        def clean_string
          original_search_tree.clean_string
        end

        def transform!
          if ["", "*"].include? @original_search_tree.clean_string.strip
            set_param("q", "*:*")
          else
            @query = transform(search_tree)
          end
        end

        def solr_params
          @config["solr_params"] || {}
        end

        def default_field
          @config["search_field_default"]
        end

        def default_attributes
          @config["search_attr_defaults"] || {}
        end

        def field_config(field)
          @config["search_fields"][field]
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
            # :nocov:
            unparseable_node(node)
          else
            raise ArgumentError, "Unknown node type #{node.node_type}"
            # :nocov:
          end
        end


        # For multiple clauses, we need to turn the search into a boolean tree.
        # Use AND by default, but can be set to "or" in teh configuration with
        # the key "default_operator"
        # @param [MLibrarySearchParser::Node::SearchNode] node
        def search_node(node)
          if node.clauses.size == 1
            transform(node.clauses.first)
          else
            case @config[:default_operator]
              when "or"
                or_node(reduce_ors(node.clauses))
              else
                and_node(reduce_ands(node.clauses))
            end
          end
        end

        # There can be any number of top-level clauses. To apply a default AND to join
        # them, recursively turn the clauses into a tree of booleans.
        # Example: A B C D turns into
        #    A AND (B AND (C AND D))
        # @param [Array<Node::BaseNode>] clauses
        # @return [Node::AndNode]
        def reduce_ands(clauses)
          if clauses.size == 1
            clauses.first
          else
            MLibrarySearchParser::Node::AndNode.new(clauses.first, reduce_ands(clauses[1..]))
          end
        end

        # @see reduce_ands
        # @return [Node::OrNode]
        def reduce_ors(clauses)
          if clauses.size == 1
            clauses.first
          else
            MLibrarySearchParser::Node::OrNode.new(clauses.first, reduce_ors(clauses[1..]))
          end
        end

      end
    end
  end
end
