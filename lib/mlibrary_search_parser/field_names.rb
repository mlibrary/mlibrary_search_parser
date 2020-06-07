# frozen_string_literal: true

require 'parslet'
require 'mlibrary_search_parser/base_types'
require 'mlibrary_search_parser/dquotes'

module MLibrarySearchParser
  module FieldNames
    include Parslet
    include BaseTypes
    include DQuotes

    # Could be set in a config file
    FIELDS = %w[anywhere title author]

    # Define rules (via define_singleton_method) for
    # each passed field name that just match that
    # token, and a rule(:fieldname) that will
    # match any of them
    def setup_fieldnames(fieldnames = FIELDS)
      fieldnames.each do |f|
        define_singleton_method(f.to_sym) { str(f) }
      end

      fname = str(fieldnames[0])
      fieldnames[1..-1].each do |f|
        fname = fname | str(f)
      end

      define_singleton_method(:fieldname) { fname }
    end

  end

end

