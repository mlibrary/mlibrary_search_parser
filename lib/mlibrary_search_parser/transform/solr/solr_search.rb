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

        # Special case an empty or single-asterisk search to mean "everything" before applying
        # the transforms.
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
          @config["search_field_default"] or raise ArgumentError.new("Configuration must define search_field_default")
        end

        def default_attributes
          @config["search_attr_defaults"] || {}
        end

        def field_config(field)
          @config["search_fields"][field] or raise ArgumentError.new("No search field '#{field]}' found")
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


        # We allow a specific set of substitutions in the search configuration attributes.
        #   * $q -- the whole solrified query
        #   * $phrase -- all the wanted tokens, turned into a phrase
        #      - alias: $qq
        #   * $tokens -- all the wanted tokens, just space-delimited, quotes stripped
        #      - alias: $t
        #   * $count / $count12 -- A count of the number of tokens, plus whatever the number is.
        #     This is potentially useful for setting mm, or constructing phrase slop queries
        #      - Examples:
        #         * `author~$count` All the tokens in any order, but all next to each other
        #         * `author~$count2` All the search tokens in any order, within count + 2 of each other

        SUB_QUERY = /\$q\b/
        SUB_PHRASE_QUERY = /\$(qq|phrase)\b/
        SUB_TOKENS_QUERY = /\$(t|tokens)\b/
        SUB_COUNT_QUERY = /\$count(\d*)\b/

        CONFIG_SUBS = {
          q: SUB_QUERY,
          phrase: SUB_PHRASE_QUERY,
          tokens: SUB_TOKENS_QUERY,
          count: SUB_COUNT_QUERY
        }

        # Take the above substitution expressions and
        # @param [String] field The field configuration to use
        # @param [MLibrarySearchParser::Node::BaseNode] node
        def substitutions(field: field, node: node)
          dictionary = {}
          attributes = {}
          q = node.clean_string
          tokens = node.wanted_tokens_string
          phrase = node.wanted_tokens_phrase
          num = node.number
          count = node.wanted_tokens.count
          field_config(field).each_pair do |attr, val|
            if SUB_QUERY.match(val)
              numbered_key = "q_#{num}"
              dictionary[numbered_key] = q
              attributes[attr] = val.gsub(SUB_QUERY, "$#{numbered_key}")
            end
            if SUB_PHRASE_QUERY.match?(val)
              numbered_key = "phrase_#{num}"
              dictionary[numbered_key] = phrase
              attributes[attr] = val.gsub(SUB_PHRASE_QUERY, "$#{numbered_key}")
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
