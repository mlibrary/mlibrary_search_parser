require_relative 'base.rb'

module MLibrarySearchParser
  class Transform
    class SolrJsonEdismax < Transform

      def solr_json_edismaxify(node: node, field: :allfields, extras: {})
        {
            edismax: {
                         qf: field,
                         v:  node.to_clean_string,
                         qq: node.tokens_phrase
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
        solr_json_edismaxify(node: node, field: :allfields, extras: extras)
      end

      def transform_and_node(node, extras: {})
        if contains_fielded?
          boolnode(node,:must).merge(extras)
        else
          solr_json_edismaxify(node, extras: extras)
        end
      end

      def transform_or_node(node, extras: {})
        if contains_fielded?
          boolnode(node,:should).merge(extras)
        else
          solr_json_edismaxify(node, extras: extras)
        end
      end

      def transform_fielded_node(node, extras: {})
        solr_json_edismaxify(node: node.query, field: node.field, extras: extras)
      end

      def transform_search_node(node, extras: {})
        if node.clauses.size == 1
          transform(clauses.first, extras: extras)
        else
          boolnode(node, :must, extras: extras)
        end
      end
    end
  end
end
