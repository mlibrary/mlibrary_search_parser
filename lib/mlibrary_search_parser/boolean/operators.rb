# frozen_string_literal: true

require 'parslet'

module MLibrarySearchParser
  module Boolean
    module Operators
      include Parslet

      rule(:and_op) { str('AND').as(:and_op) }
      rule(:or_op) { str('OR').as(:or_op) }
      rule(:not_op) { str('NOT').as(:not_op) }
      rule(:any_op) { and_op | or_op | not_op }


    end
  end
end

