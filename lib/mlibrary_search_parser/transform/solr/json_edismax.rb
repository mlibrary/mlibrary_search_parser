# frozen_string_literal: true

require "mlibrary_search_parser/node"
require_relative "solr_search"
require_relative "utilities"
require "mlibrary_search_parser/node/search"

module MLibrarySearchParser
  module Transformer
    module Solr
      class JsonEdismax
        include Utilities

        def initialize(config:)
          @config = config
          @solr_search = SolrSearch.new
        end

        # @param [MLibrarySearchParser::Node::Search] query
        # @return [MLibrarySearchParser::Transform::SolrSearch]
        def to_search(query)
          q = query.deep_dup { |n| lucene_escape_node(n) }
          q.renumber!
          transform(q, SolrSearch.new)
        end

        # Dispatch to specific methods for transforming
        # each node type
        # @param [MLibrarySearchParser::Node::BaseNode] node
        # @param [MLibrarySearchParser::Transform::SolrSearch] ss
        # @return [??] depends on that transformation being done
        def transform(node, ss)
          case node.node_type
          when :tokens
            tokens_node(node, ss)
          when :fielded
            fielded_node(node, ss)
          when :search
            search_node(node, ss)
          when :and
            and_node(node, ss)
          when :or
            or_node(node, ss)
          when :not
            not_node(node, ss)
          else
            raise ArgumentError, "Unknown node type #{node.node_type}"
          end
        end

        # Create a json structure suitable for sending as a query to solr
        # as an edismax search
        #
        # Doesn't do anything fancy; just fill in the qf as derived from the
        # field name and the value, plus anything else that's sent along
        def edismaxify(node, ss)
          v = node.to_clean_string
          {
            edismax: {
              qf: field,
              v: v
            }
          }
        end

        # Create a bool node where the "positive" (non-negated) items go into the should/must,
        # and the negated clauses go into the must_not
        # @todo Deal with double-negation
        def boolnode(node, shouldmust)
          pos = node.positives.map { |x| transform(x) }
          neg = node.negatives.map { |x| transform(x) }
          q = {
            bool: {shouldmust.to_sym => pos}
          }
          q[:bool][:must_not] = neg if neg.size.positive?
          q
        end

        def tokens_node(node, extras: {})
          edismaxify(node, extras: extras, escape: true)
        end

        def and_node(node, extras: {})
          if node.contains_fielded?
            boolnode(node, :must)
          else
            edismaxify(node, extras: extras)
          end
        end

        def or_node(node, extras: {})
          if node.contains_fielded?
            boolnode(node, :should)
          else
            edismaxify(node, extras: extras)
          end
        end

        def fielded_node(node, extras: {})
          edismaxify(node.query, field: node.field, extras: extras)
        end

        def search_node(node, extras: {})
          if node.clauses.size == 1
            transform(node.clauses.first, extras: extras)
          else
            boolnode(node, :must)
          end
        end
      end
    end
  end
end
