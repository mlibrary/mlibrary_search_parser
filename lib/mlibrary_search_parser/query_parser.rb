require "parslet"
require "json"
require "pry"
require "mlibrary_search_parser/node"
require "mlibrary_search_parser/search_handler"
require "mlibrary_search_parser/search"

module MLibrarySearchParser
  class Error < StandardError; end

  class BaseParser < Parslet::Parser
    ###################################
    # BASICS
    ###################################

    rule(:space) { match['\\s'].repeat(1) }
    rule(:space?) { space.maybe }

    rule(:lparen) { str("(") >> space? }
    rule(:rparen) { space? >> str(")") }

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

    rule(:smart_dash) { (str("\u2013") | str("\u2014") | str("\u2015")).as(:smart_dash) }

    rule(:smart_underscore) { str("\u2017").as(:smart_underscore) }

    rule(:smart_comma) { str("\u201a").as(:smart_comma) }

    rule(:smart_squote) {
      (str("\u2018") | str("\u2019") |
        str("\u201b") | str("\u2032")).as(:smart_squote)
    }

    rule(:smart_dquote) {
      (str("\u201c") | str("\u201d") |
        str("\u201e") | str("\u201f") | str("\u2033")).as(:smart_dquote)
    }

    rule(:smartquote) { smart_squote | smart_dquote }

    rule(:smart_char) { smart_underscore | smart_comma | smart_dash | smartquote }

    ###################################
    # Phrase: Double-quoted strings
    ###################################
    # Phrases can have anything in them except a double-quote character

    rule(:phrase) { dquote >> nondquote.repeat(1) >> dquote }
  end

  class SpecialCharParser < BaseParser
    rule(:simple_char) { any.as(:simple_char) }
    rule(:composite_string) { (smart_char | simple_char).repeat.as(:composite_string) }
    root(:composite_string)
  end

  class SpecialCharTransformer < Parslet::Transform
    rule(smart_underscore: simple(:u)) { "_" }
    rule(smart_comma: simple(:c)) { "," }
    rule(smart_dash: simple(:d)) { "-" }
    rule(smart_squote: simple(:q)) { "'" }
    rule(smart_dquote: simple(:q)) { '"' }
    rule(simple_char: simple(:s)) { s }
    rule(composite_string: sequence(:s)) { s.join("") }
  end

  class FieldParser < BaseParser
    # @param [Array<String>] fieldnames Names of the indexed files (title, author)
    def initialize(fieldnames)
      super()
      setup_fieldnames(fieldnames)
    end

    def setup_fieldnames(flist)
      tmp = str(flist.first)
      flist[1..].each { |x| tmp |= str(x) }
      define_singleton_method(:field_name) { tmp.as(:field_name) >> colon }
    end
  end

  class PreQueryParenthesisParser < BaseParser
    rule(:word) { match['^\(\)\s'].repeat(1) }
    rule(:token) { phrase | word }
    rule(:tokens) { token >> (space >> tokens).repeat(0) >> space? }
    rule(:balanced_parens) { lparen >> (tokens | balanced_parens).repeat >> rparen >> space? }
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
    rule(:parens) { lparen >> tokens >> rparen | tokens.as(:tokens) | fielded.as(:fielded) | lparen >> (fielded.as(:fielded) >> space?).repeat(2) >> rparen }
    rule(:parens_without_field) { lparen >> tokens >> rparen | tokens.as(:tokens) }
    rule(:full_query) { (space? >> parens >> space?).repeat }
    root(:full_query)
  end

  class FallbackParser < Parslet::Parser
    rule(:unparseable) { any.repeat(0).as(:unparseable) }
    root(:unparseable)
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
    rule(:token_parens) { any_op.absent? >> fielded.absent? >> lparen >> token >> (space >> tokens).repeat(0) >> rparen }
    rule(:tokens) { any_op.absent? >> fielded.absent? >> token >> (space >> tokens).repeat(0) | token_parens }

    #######################################
    # FIELDS
    # ####################################

    rule(:fielded) { field_name >> parens.as(:query) }

    #######################################
    # BINARY OPERATORS
    # ####################################

    rule(:and_op) { space? >> str("AND") >> space }
    rule(:or_op) { space? >> str("OR") >> space }
    rule(:binary_op) { and_op | or_op }

    #######################################
    # UNARY OPERATORS
    #####################################

    rule(:not_op) { space? >> str("NOT") >> space }

    rule(:any_op) { binary_op | not_op }

    #######################################
    # BASIC OPERATOR EXPRESSIONS
    #####################################
    # These include the normal booleans and NOT, where we
    # have spaces around them

    rule(:parens) do
      lparen >> or_expr >> rparen |
        tokens.as(:tokens) |
        fielded.as(:fielded) |
        multi_parens
    end
    rule(:multi_parens) { lparen >> (parens >> space?).repeat.as(:multi_parens) >> rparen | multi_op_parens.as(:multi_parens) }
    rule(:not_expr) { not_op >> parens.as(:not) | parens >> space? }
    rule(:and_expr) { (not_expr.as(:left) >> and_op >> binary_op.maybe >> and_expr.as(:right)).as(:and) | not_expr }
    rule(:or_expr) { (and_expr.as(:left) >> or_op >> binary_op.maybe >> or_expr.as(:right)).as(:or) | and_expr }

    rule(:multi_op) { (or_expr >> space?).repeat(2) }
    rule(:multi_op_parens) { lparen >> multi_op >> rparen }

    rule(:bare_expr) { (or_expr >> (space? >> or_expr).repeat(0)) }

    rule(:search) { space? >> bare_expr.repeat(0).as(:search) >> space? }
    root(:search)
  end

  class QueryTransformer < Parslet::Transform
    rule(multi_parens: sequence(:t)) { Node::SearchNode.new(t) }
    rule(tokens: simple(:t)) { Node::TokensNode.new(t.to_s) }
    rule(and: {left: simple(:l), right: simple(:r)}) {
      Node::AndNode.new(l, r)
    }
    rule(or: {left: simple(:l), right: simple(:r)}) {
      Node::OrNode.new(l, r)
    }
    rule(not: simple(:n)) { Node::NotNode.new(n) }
    rule(fielded: {field_name: simple(:fn), query: simple(:q)}) { Node::FieldedNode.new(fn.to_s, q) }
    rule(search: simple(:s)) { Node::SearchNode.new(s) }
    rule(search: sequence(:s)) { Node::SearchNode.new(s) }
    rule(search: subtree(:s)) { Node::SearchNode.new(s) }
    rule(unparseable: simple(:u)) { Node::SearchNode.new(Node::UnparseableNode.new(u)) }
  end
end
