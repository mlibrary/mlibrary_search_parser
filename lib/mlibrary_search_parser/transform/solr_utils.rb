module MLibrarySearchParser
  class Transform
    module SolrUtils

      # We don't escape double-quotes, parens because anything that's there
      # is already validated as part of a phrase
      LUCENE_SPECIAL_CHARS_RE = /([!{}\[\]"^~?:])/
      LUCENE_REMOVE_CHARS_RE = /([!{}\[\]^~?:])/

      def lucene_escape(str)
        str.gsub(LUCENE_SPECIAL_CHARS_RE, '\\\\\1').
            gsub(/(?:\|\||&&)/, '')
      end

      def lucene_remove(str)
        str.gsub('"', '').gsub(LUCENE_REMOVE_CHARS_RE, '').
            gsub(/(?:\|\||&&)/, '')
      end

      def lucene_escape_node(node)
        node.deep_dup do |n|
          if n.tokens_node?
            n.class.new(lucene_escape(n.text))
          else
            n
          end
        end
      end
    end
  end
end
