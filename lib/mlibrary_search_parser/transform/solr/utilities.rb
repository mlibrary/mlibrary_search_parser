# frozen_string_literal: true

module MLibrarySearchParser
  module Transformer
    module Solr
      module Utilities
        # We don't escape double-quotes, parens because anything that's there
        # is already validated as part of a phrase
        LUCENE_SPECIAL_CHARS_RE = /([!{}\[\]^~?:])/
        QUOTED_RE = /\A".*?"\Z/
        PLUS_MINUS_SPACE = /([-+])(\s+|\Z)/

        # Lucene escape syntax for char C is essentially '\C'
        # but we need to escape the \, and then escape the \
        # that is itself escaping the backslash, so we get
        # \\\\C. On top of that, the ruby syntax for getting
        # at a numbered regexp match is '\1', so we end up
        # with '\\\\\1'
        def lucene_escape(str)
          escaped = str.gsub(LUCENE_SPECIAL_CHARS_RE, '\\\\\1')
            .gsub(/(?:\|\||&&)/, " ")
          escaped = escape_asterisks_followed_by_something(escaped)
          escape_plus_minus_followed_by_space(escaped)
        end

        # We want to hang onto any asterisks that come at the end of
        # a word and eliminate the others
        ASTR = /(?<pre>\A.*[\p{L}\d])\*(?<post>[^\p{Z}].*)/
        def escape_asterisks_followed_by_something(str)
          m = ASTR.match(str)
          if m
            m["pre"] + '\\*' + m["post"]
          else
            str
          end
        end

        # Solr allows a space after a +/-, treating it as a should/shouldn't
        # (e.g., _a + b_ is treated as _a +b_), but our syntax
        # does not. When not in a phrase, escape
        # either of those characters that are followed by a space or EOS
        def escape_plus_minus_followed_by_space(str)
          return str if QUOTED_RE.match(str)
          str.gsub(PLUS_MINUS_SPACE, '\\\\\1\2')
        end

        def lucene_escape_node(node)
          node.deep_dup do |n|
            if n.is_type?(:tokens)
              n.class.new(lucene_escape(n.text))
            else
              n
            end
          end
        end
      end
    end
  end
end
