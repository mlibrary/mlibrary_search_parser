# frozen_string_literal: true

require 'parslet'
require 'mlibrary_search_parser/boolean/tokens'

module MLibrarySearchParser
  module Boolean
    module Expressions
      include Parslet
      include BaseTypes
      include Tokens


      rule(:and_op) { space? >> str('AND') >> space? }
      rule(:or_op) { space? >> str('OR') >> space? }
      rule(:not_op) { space? >> str('NOT') >> space? }

      rule(:any_op) { not_op | or_op | and_op }

      rule(:parens) { lparen >> or_expr >> rparen | tokens }
      rule(:not_expr) { not_op >> parens.as(:not) | parens }
      rule(:and_expr) { (not_expr.as(:left) >> and_op >> and_expr.as(:right)).as(:and) | not_expr }
      rule(:or_expr) { (and_expr.as(:left) >> or_op >> or_expr.as(:right)).as(:or) | and_expr }

      rule(:expr) { (space? >> or_expr >> and_expr.repeat(0) >> space?).as(:search) }

    end
  end
end
