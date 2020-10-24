# frozen_string_literal: true

require_relative 'base'
require_relative 'solr_utils'

module MLibrarySearchParser
  module Transform
    class SolrJsonEdismax < Transform
      include SolrUtils
      include Base

      # Create a json structure suitable for sending as a query to solr
      # as an edismax search
      #
      # Doesn't do anything fancy; just fill in the qf as derived from the
      # field name and the value, plus anything else that's sent along
      def edismaxify(field, value, **kwargs)
        v = node.to_clean_string
        {
          edismax: {
            qf: field,
            v: v
          }.merge(extras)
        }
      end

      # Create a bool node where the "positive" (non-negated) items go into the should/must,
      # and the negated clauses go into the must_not
      # @todo Deal with double-negation
      def boolnode(node, shouldmust)
        pos = node.positives.map { |x| transform(x) }
        neg = node.negatives.map { |x| transform(x) }
        q   = {
          bool: { shouldmust.to_sym => pos}
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
