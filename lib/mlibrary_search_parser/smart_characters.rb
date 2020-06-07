# frozen_string_literal: true

require 'parslet'

module MLibrarySearchParser
  module SmartCharacters
    include Parslet

    rule(:smart_dash) { str("\u2013") | str("\u2014") | str("\u2015") }

    rule(:smart_squote) { str("\u2018") | str("\u2019") |
      str("\u201b") | str("\u2032") }

    rule(:smart_underscore) { str("\u2017") }

    rule(:smart_comma) { str("\u201a") }

    rule(:smart_dquote) { str("\u201c") | str("\u201d") |
      str("\u201e") | str("\u2033") }

    rule(:smartquote) { smart_squote | smart_dquote }
  end
end

__END__
    "\u2013" => "-"
    "\u2014" => "-"
    "\u2015" => "-"

    "\u2017" => "_"

    "\u2018" => "'"
    "\u2019" => "'"
    "\u201b" => "'"
    "\u2032" => "'"

    "\u201a" => ","

    "\u201c" => "\""
    "\u201d" => "\""
    "\u201e" => "\""
    "\u2033" => "\""
