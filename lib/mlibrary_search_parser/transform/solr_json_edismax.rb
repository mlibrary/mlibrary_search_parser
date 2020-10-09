require_relative '../transform'
module MLibrarySearchParser
  class Transform
    class SolrJsonEdismax < Transform

      LUCENE_SPECIAL_CHARS_RE = /([!{}\[\]^"~?:])/
      def solr_json_edismaxify(node, field: :allfields, extras: {})
        v = lucene_escape node.to_clean_string
        qq = lucene_remove node.tokens_phrase
        {
            edismax: {
                         qf: field,
                         v:  v,
                         qq: qq
                     }.merge(extras)
        }
      end

      def lucene_escape(str)
        str.gsub(LUCENE_SPECIAL_CHARS_RE, '\\\\\1').
            gsub(/(?:\|\||&&)/, '')
      end

      def lucene_remove(str)
        str.gsub(LUCENE_SPECIAL_CHARS_RE, '').
            gsub(/(?:\|\||&&)/, '')
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
        # escaped_node = MLibrarySearchParser::Node::TokensNode.new(lucene_escape(node.text))
        solr_json_edismaxify(node, field: :allfields, extras: extras)
      end

      def transform_and_node(node, extras: {})
        if node.contains_fielded?
          boolnode(node,:must).merge(extras)
        else
          solr_json_edismaxify(node, extras: extras)
        end
      end

      def transform_or_node(node, extras: {})
        if node.contains_fielded?
          boolnode(node,:should).merge(extras)
        else
          solr_json_edismaxify(node, extras: extras)
        end
      end

      def transform_fielded_node(node, extras: {})
        solr_json_edismaxify(node.query, field: node.field, extras: extras)
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
