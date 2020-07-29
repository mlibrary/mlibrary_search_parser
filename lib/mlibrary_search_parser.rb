require 'parslet'
require 'json'
require 'pry'
require "mlibrary_search_parser/node/boolean"
require "mlibrary_search_parser/node/unary"
require "mlibrary_search_parser/node/fielded"
require "mlibrary_search_parser/node/search"
require "mlibrary_search_parser/node/node"
require 'mlibrary_search_handler'
require "search"

module MLibrarySearchParser
  class Error < StandardError; end

  class BaseParser < Parslet::Parser

    ###################################
    # BASICS
    ###################################

    rule(:space) { match['\\s'].repeat(1) }
    rule(:space?) { space.maybe }

    rule(:lparen) { str('(') >> space? }
    rule(:rparen) { space? >> str(')') }

    rule(:empty_string) { str("") }
    rule(:colon) { str(":") }

    rule(:dquote) { str('"') }
    rule(:squote) { str("'") }
    rule(:nondquote) { match['^"'].repeat(1) }
    rule(:nonsquote) { match["^'"].repeat(1) }
    #
    ##################################################
    # "Smart" quotes and other near-miss characters
    ##################################################

    rule(:smart_dash) { str("\u2013") | str("\u2014") | str("\u2015") }

    rule(:smart_underscore) { str("\u2017") }

    rule(:smart_comma) { str("\u201a") }

    rule(:smart_squote) { str("\u2018") | str("\u2019") |
      str("\u201b") | str("\u2032") }

    rule(:smart_dquote) { str("\u201c") | str("\u201d") |
      str("\u201e") | str("\u2033") }

    rule(:smartquote) { smart_squote | smart_dquote }

    ###################################
    # Phrase: Double-quoted strings
    ###################################
    # Phrases can have anything in them except a double-quote character

    rule(:phrase) { dquote >> nondquote.repeat(1) >> dquote }

  end

  class FieldParser < BaseParser
    # @param [Array<String>] fieldnames Names of the indexed files (title, author)
    def initialize(filename)
      super()
      field_file = File.read(filename)
      field_obj = JSON.parse(field_file)
      setup_fieldnames(field_obj.keys)
    end

    def setup_fieldnames(flist)
      tmp = str(flist.first)
      flist[1..-1].each {|x| tmp = tmp | str(x)}
      define_singleton_method(:field_name) { tmp.as(:field_name) >> colon }
    end

  end

  class PreQueryParenthesisParser < BaseParser
    rule(:word) { match['^\(\)\s'].repeat(1) }
    rule(:token) { phrase | word }
    rule(:tokens) { token >> (space >> tokens).repeat(0) >> space? }
    rule(:balanced_parens) { lparen >> (tokens | balanced_parens).repeat >> rparen }
    rule(:full_query) { (space? >> (balanced_parens | tokens) >> space?).repeat }
    root(:full_query)
  end

  class PreQueryDoubleQuotesParser < BaseParser
    rule(:word) { nondquote.repeat(1) }
    rule(:tokens) { word >> (space >> tokens).repeat(0) >> space? }
    rule(:balanced_quotes) { dquote >> (tokens | balanced_quotes).repeat >> dquote }
    rule(:full_query) { (space? >> (balanced_quotes | tokens) >> space?).repeat }
    root(:full_query)
  end

  class PreQueryNestedFieldsParser < FieldParser
    rule(:word_char) { match['^\(\)\"\s'] }
    rule(:word) { word_char.repeat(1) }
    rule(:token) { word | phrase }
    rule(:fielded) { field_name >> parens_without_field.as(:query) }
    rule(:tokens) { fielded.absent? >> token >> (space >> tokens).repeat(0) }
    rule(:parens) { lparen >> tokens >> rparen | tokens.as(:tokens) | fielded.as(:fielded) }
    rule(:parens_without_field) { lparen >> tokens >> rparen | tokens.as(:tokens) }
    rule(:full_query) { (space? >> parens >> space?).repeat }
    root(:full_query)

  end

  class QueryParser < FieldParser



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
    rule(:tokens) { any_op.absent? >> fielded.absent? >> token >> (space >> tokens).repeat(0) }

    #######################################
    # FIELDS
    # ####################################

    rule(:fielded) { field_name >> parens.as(:query) }

    #######################################
    # BINARY OPERATORS
    # ####################################

    rule(:and_op) { space? >> str('AND') >> space }
    rule(:or_op)  { space? >> str('OR') >> space }
    rule(:binary_op) { and_op | or_op }

    #######################################
    # UNARY OPERATORS
    #####################################

    rule(:not_op) { space? >> str('NOT')  >> space }

    rule(:any_op) { binary_op | not_op }

    #######################################
    # BASIC OPERATOR EXPRESSIONS
    #####################################
    # These include the normal booleans and NOT, where we
    # have spaces around them

    rule(:parens) { lparen >> or_expr >> rparen | tokens.as(:tokens) | fielded.as(:fielded) }
    rule(:not_expr) { not_op >> parens.as(:not) | parens >> space? }
    rule(:and_expr) { (not_expr.as(:left) >> and_op >> binary_op.maybe >> and_expr.as(:right)).as(:and) | not_expr }
    rule(:or_expr) { (and_expr.as(:left) >> or_op >> binary_op.maybe >> or_expr.as(:right)).as(:or) | and_expr }

    rule(:bare_expr) { (or_expr >> not_expr.repeat(0)) }

    rule(:search) { space? >> (bare_expr.repeat(0)).as(:search) >> space? }
    root(:search)
  end

  class QueryTransformer < Parslet::Transform
    rule(:tokens => simple(:t)) { Node::TokensNode.new(t.to_s) }
    rule(:and => { :left => simple(:l), :right => simple(:r) } ) {
      Node::AndNode.new(l, r)
    }
    rule(:or => { :left => simple(:l), :right => simple(:r) } ) {
      Node::OrNode.new(l,r)
    }
    rule(:not => simple(:n)) { Node::NotNode.new(n) }
    rule(:fielded => { :field_name => simple(:fn), :query => simple(:q) }) { Node::FieldedNode.new(fn, q) }
    rule(:search => simple(:s)) { Node::SearchNode.new(s) }
    rule(:search => sequence(:s)) { Node::SearchNode.new(s) }
    rule(:search => subtree(:s)) { Node::SearchNode.new(s) }
  end
end
