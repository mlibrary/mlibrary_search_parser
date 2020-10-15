require_relative '../transform'
require_relative 'solr_utils'

module MLibrarySearchParser
  class Transform
    class SolrJsonEdismax < Transform

      include SolrUtils


      def edismaxify(node, field: :allfields, extras: {}, escape: false)
        v = node.to_clean_string
        {
            edismax: {
                         qf: field,
                         v:  v,
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
            bool: {shouldmust.to_sym => pos}
        }
        if neg.size > 0
          q[:bool][:must_not] = neg
        end
        q
      end

      def transform_tokens_node(node, extras: {})
        edismaxify(node, extras: extras, escape: true)
      end

      def transform_and_node(node, extras: {})
        if node.contains_fielded?
          boolnode(node,:must)
        else
          edismaxify(node, extras: extras)
        end
      end

      def transform_or_node(node, extras: {})
        if node.contains_fielded?
          boolnode(node,:should)
        else
          edismaxify(node, extras: extras)
        end
      end

      def transform_fielded_node(node, extras: {})
        edismaxify(node.query, field: node.field, extras: extras)
      end

      def transform_search_node(node, extras: {})
        if node.clauses.size == 1
          transform(node.clauses.first, extras: extras)
        else
          boolnode(node, :must)
        end
      end
    end
  end
end
