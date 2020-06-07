# frozen_string_literal: true

require 'parslet'

module MLibrarySearchParser
  module BaseTypes
    include Parslet

    rule(:empty_string) { str("") }
    rule(:lparen) { str('(') >> space? }
    rule(:rparen) { space? >> str(')') }

    rule(:space) { match['\\s'].repeat(1) }
    rule(:space?) { space.maybe }

    rule(:dot) { str('.') }
    rule(:dot?) { dot.maybe }

    rule(:plus) { str('+') }
    rule(:minus) { str('-') }
    rule(:dash) { str('-') }
    rule(:amp) { str('&') }

    rule(:dquote) { str('"') }
    rule(:squote) { str("'") }
    rule(:nondquote) { match['^"'].repeat(1) }
    rule(:nonsquote) { match["^'"].repeat(1) }

    rule(:colon) { str(':') }

    rule(:langle) { str('<') }
    rule(:rangle) { str('>') }
    rule(:lsquare) { str('[') }
    rule(:rsuare) { str(']') }

    rule(:digit) { match('\d') }
    rule(:digits) { digit.repeat(1) }
    rule(:digits?) { digits.maybe }

  end
end
