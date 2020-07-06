require "mlibrary_search_parser/version"
require 'parslet'

module MLibrarySearchParser
  class Error < StandardError; end


  include Parslet

  ###################################
  # BASICS
  ###################################
  rule(:empty_string) { str("") }
  rule(:lparen) { str('(') >> space? }
  rule(:rparen) { space? >> str(')') }

  rule(:space) { match['\\s'].repeat(1) }
  rule(:space?) { space.maybe }

  rule(:dquote) { str('"') }
  rule(:squote) { str("'") }
  rule(:nondquote) { match['^"'].repeat(1) }
  rule(:nonsquote) { match["^'"].repeat(1) }

  ##################################################
  # "Smart" quotes and other near-miss characters
  ##################################################

  rule(:smart_dash) { str("\u2013") | str("\u2014") | str("\u2015") }

  rule(:smart_squote) { str("\u2018") | str("\u2019") |
    str("\u201b") | str("\u2032") }

  rule(:smart_underscore) { str("\u2017") }

  rule(:smart_comma) { str("\u201a") }

  rule(:smart_dquote) { str("\u201c") | str("\u201d") |
    str("\u201e") | str("\u2033") }

  rule(:smartquote) { smart_squote | smart_dquote }



  ###################################
  # Phrase: Double-quoted strings
  ###################################
  # Phrases can have anything in them except a double-quote character

  rule(:phrase) { dquote >> nondquote.repeat(1) >> dquote }

  ###################################
  # Words
  ###################################
  #  A word, in this case, is a string of characters that doesn't
  # include any of the reserved characters (,), or ", or a space

  rule(:word_char) { match['^\(\)\"\s'] }
  rule(:word) { word_char.repeat(1) }

  ###################################
  # Tokens
  ###################################
  # A token is a logic word-unit. So, either a word, or a phrase
  # that we treat as a single "word"

  rule(:token) { phrase | word }
  rule(:tokens) { any_op.absent? >> token >> (space >> tokens).repeat(0) }

  #######################################
  # BINARY OPERATORS
  # ####################################

  rule(:and_op) { space? >> str('AND') >> space }
  rule(:or_op) { space? >> str('OR') >> space }

  #######################################
  # UNARY OPERATORS
  #####################################

  rule(:not_op) { space? >> str('NOT')  >> space }

  rule(:any_op) { and_op | or_op | not_op }

  #######################################
  # BASIC OPERATOR EXPRESSIONS
  #####################################
  # These include the normal booleans and NOT, where we
  # have spaces around them
  #
  # No fieldeds are allowed here

  rule(:parens) { lparen >> or_expr >> rparen | tokens }
  rule(:not_expr) { not_op >> parens.as(:not) | parens }
  rule(:and_expr) { (not_expr.as(:left) >> and_op >> and_expr.as(:right)).as(:and) | not_expr }
  rule(:or_expr) { (and_expr.as(:left) >> or_op >> or_expr.as(:right)).as(:or) | and_expr }

  rule(:bare_expr) { (or_expr >> not_expr.repeat(0)) }

  rule(:search) { space? >> (bare_expr.repeat(0)).as(:search) >> space? }
end
