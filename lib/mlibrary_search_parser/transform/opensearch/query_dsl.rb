# frozen_string_literal: true

require "mlibrary_search_parser/node"

module MLibrarySearchParser
  module Transformer
    module OpenSearch
      # Transforms the AST to OpenSearch Query DSL format
      class QueryDSL
        attr_accessor :config

        def initialize(config:, **kwargs)
          @config = config
        end

        # Main entry point - transforms a node to OpenSearch Query DSL
        # @param [BaseNode] node The AST node to transform
        # @return [Hash] OpenSearch Query DSL
        def transform(node)
          case node.node_type
          when :search
            transform_search(node)
          when :tokens
            transform_tokens(node)
          when :and
            transform_and(node)
          when :or
            transform_or(node)
          when :not
            transform_not(node)
          when :fielded
            transform_fielded(node)
          when :empty
            transform_empty(node)
          when :unparseable
            transform_tokens(node)
          else
            # Fallback for unknown node types
            {match_all: {}}
          end
        end

        # Transform SearchNode - wraps clauses in query structure
        def transform_search(node)
          return {query: {match_all: {}}} if node.clauses.empty?

          # Separate positive and negative clauses
          positive_clauses = node.clauses.reject { |c| c.node_type == :not }
          negative_clauses = node.clauses.select { |c| c.node_type == :not }

          if negative_clauses.empty?
            # No negation, simple case
            if positive_clauses.length == 1
              # Single clause - transform it directly
              {query: transform(positive_clauses.first)}
            else
              # Multiple clauses - combine with AND (must)
              {
                query: {
                  bool: {
                    must: positive_clauses.map { |clause| transform(clause) }
                  }
                }
              }
            end
          else
            # Has negation - need bool query with must_not
            bool_query = {}

            if positive_clauses.length == 1
              # Single positive clause
              bool_query[:must] = [transform(positive_clauses.first)]
            elsif positive_clauses.length > 1
              # Multiple positive clauses
              bool_query[:must] = positive_clauses.map { |clause| transform(clause) }
            end

            # Add negative clauses
            bool_query[:must_not] = negative_clauses.map { |clause| transform(clause.operand) }

            {
              query: {
                bool: bool_query
              }
            }
          end
        end

        # Transform TokensNode to match or match_phrase
        def transform_tokens(node)
          text = node.text.to_s.strip
          return {match_all: {}} if text.empty?

          # Check if it's a phrase (enclosed in quotes)
          if text.start_with?('"') && text.end_with?('"')
            # Phrase query
            phrase = text.delete('"')
            if @config[:query_fields] && !@config[:query_fields].empty?
              # Use first query field for phrase matching
              field = @config[:query_fields].first
              {match_phrase: {field => phrase}}
            else
              # Default to _all field
              {match_phrase: {_all: phrase}}
            end
          elsif text.include?('*') || text.include?('?')
            # Wildcard query
            {query_string: {query: text, default_operator: "AND"}}
          else
            # Regular match query
            if @config[:query_fields] && !@config[:query_fields].empty?
              # Multi-field match
              {
                multi_match: {
                  query: text,
                  fields: @config[:query_fields],
                  type: "best_fields"
                }
              }
            else
              # Simple match
              {match: {_all: text}}
            end
          end
        end

        # Transform AndNode to bool with must
        def transform_and(node)
          left_query = node.left
          right_query = node.right

          # Collect all clauses that should be in must or must_not
          must_clauses = []
          must_not_clauses = []

          # Process left side
          if left_query.node_type == :not
            must_not_clauses << transform(left_query.operand)
          elsif left_query.node_type == :and
            # Flatten nested AND
            nested = transform(left_query)
            must_clauses.concat(extract_must_clauses(nested))
            must_not_clauses.concat(extract_must_not_clauses(nested))
          else
            must_clauses << transform(left_query)
          end

          # Process right side
          if right_query.node_type == :not
            must_not_clauses << transform(right_query.operand)
          elsif right_query.node_type == :and
            # Flatten nested AND
            nested = transform(right_query)
            must_clauses.concat(extract_must_clauses(nested))
            must_not_clauses.concat(extract_must_not_clauses(nested))
          else
            must_clauses << transform(right_query)
          end

          # Build the bool query
          bool_query = {must: must_clauses}
          bool_query[:must_not] = must_not_clauses unless must_not_clauses.empty?

          {bool: bool_query}
        end

        # Transform OrNode to bool with should
        def transform_or(node)
          left_query = transform(node.left)
          right_query = transform(node.right)

          # Flatten nested OR nodes for cleaner output
          should_clauses = []
          should_clauses.concat(extract_should_clauses(left_query))
          should_clauses.concat(extract_should_clauses(right_query))

          {
            bool: {
              should: should_clauses,
              minimum_should_match: 1
            }
          }
        end

        # Transform NotNode to negation context
        # NOT nodes need special handling as they must be part of a bool query
        def transform_not(node)
          {
            bool: {
              must_not: [transform(node.operand)]
            }
          }
        end

        # Transform FieldedNode to field-specific query
        def transform_fielded(node)
          field_name = node.field.to_s
          inner_query = node.query

          case inner_query.node_type
          when :tokens
            text = inner_query.text.to_s.strip.delete('"')
            if inner_query.text.start_with?('"') && inner_query.text.end_with?('"')
              # Phrase query on specific field
              {match_phrase: {field_name => text}}
            elsif text.include?('*') || text.include?('?')
              # Wildcard on specific field
              {wildcard: {field_name => text.downcase}}
            else
              # Regular match on specific field
              {match: {field_name => text}}
            end
          when :and, :or, :not
            # For Boolean operations on fielded queries, we need to transform recursively
            transform(inner_query)
          else
            # Default: match query
            {match: {field_name => inner_query.to_s}}
          end
        end

        # Transform empty nodes
        def transform_empty(node)
          {match_all: {}}
        end

        private

        # Extract must clauses from a query, flattening if already a bool/must
        def extract_must_clauses(query)
          if query.is_a?(Hash) && query[:bool] && query[:bool][:must]
            Array(query[:bool][:must])
          else
            [query]
          end
        end

        # Extract must_not clauses from a query, flattening if already a bool/must_not
        def extract_must_not_clauses(query)
          if query.is_a?(Hash) && query[:bool] && query[:bool][:must_not]
            Array(query[:bool][:must_not])
          else
            []
          end
        end

        # Extract should clauses from a query, flattening if already a bool/should
        def extract_should_clauses(query)
          if query.is_a?(Hash) && query[:bool] && query[:bool][:should]
            Array(query[:bool][:should])
          else
            [query]
          end
        end
      end
    end
  end
end

