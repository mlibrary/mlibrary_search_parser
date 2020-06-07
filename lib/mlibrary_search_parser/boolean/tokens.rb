# frozen_string_literal: true

require 'parslet'
require 'mlibrary_search_parser/dquotes'
require 'mlibrary_search_parser/boolean/operators'

module MLibrarySearchParser
  module Boolean
    module Tokens
      include Parslet
      include Operators
      include DQuotes

      rule(:wordchar) { match['^\s\)\(\"'] }
      rule(:minus_token) { dash >> basic_token }
      rule(:plus_token) { plus >> basic_token }
      rule(:word) { wordchar.repeat(1) }

      rule(:term) { any_op.absent? >> word }
      rule(:terms) { (term >> (space >> term).repeat(0)).repeat(1) }

      rule(:terms) {
        term >> (space >> term).repeat(0)
      }

      rule(:token) { dquoted_phrase.as(:phrase) | terms.as(:terms) }

      rule(:tokens) {
        token >> ((space >> token).repeat(0)).maybe
      }
    end
  end
end

