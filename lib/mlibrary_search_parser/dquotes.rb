# frozen_string_literal: true

require 'parslet'
require 'mlibrary_search_parser/base_types'

module MLibrarySearchParser
  module DQuotes
    include Parslet
    include BaseTypes
    rule(:non_dquote_char) { match['^\"'] }
    rule(:non_dquote_chars) { non_dquote_char.repeat(1) }

    rule(:non_dquote_term_char) { match['^\"\s'] }
    rule(:non_dquote_term) { non_dquote_term_char.repeat(1) }
    rule(:dquoted_phrase) {
      dquote >> space? >>
        (non_dquote_term >>
          (space >> non_dquote_term).repeat(0)) >>
        space? >> dquote
    }
  end
end

