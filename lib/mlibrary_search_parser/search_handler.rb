require 'json'
require 'dotenv/load'

module MLibrarySearchParser
  class ParseError
    DETAILS = "ParseError"
    SUMMARY = "ParseError"
    attr_reader :original, :actual

    def initialize(original = nil, actual = nil)
      @original = original
      @actual = actual
    end

    def details
      self.class::DETAILS
    end

    def summary
      self.class::SUMMARY
    end

    def to_h
      {
        details: details,
        summary: summary,
        original: original,
        actual: actual,
      }
    end
  end

  class UnevenParensError < ParseError
    DETAILS = <<-EOF
<strong>Unpaired parentheses detected.</strong> If you meant to group certain terms together, make sure the intended terms are enclosed with a pair of opening and closing parentheses.
    EOF
  end

  class UnevenQuotesError < ParseError
    DETAILS = <<-EOF
<strong>An unpaired quotation mark was detected.</strong> If you meant to search for a phrase, make sure it is enclosed with a pair of opening and closing quotation marks.
    EOF
  end

  class NestedFieldsError < ParseError
    DETAILS = <<-EOF
<strong>One or more parentheses removed.</strong> When including <strong>author:</strong>, <strong>title:</strong>, or other fields in a search, an error can occur if fields are grouped together with parentheses incorrectly. See <a href="https://guides.lib.umich.edu/c.php?g=914690&amp;p=6590011">Tips for Using Library Search</a> for help or revise your search to run again.
    EOF
  end

  class UnparseableError < ParseError
    DETAILS = <<-EOF
<strong>Not able to run requested search due to conflicting parameters.</strong> Edit your search terms above to revise and rerun this search. See <Research Guide> for search help.
    EOF
  end

  class MiniSearch
    attr_accessor :search_string, :errors, :warnings

    def initialize(search_string, errors = [])
      @search_string = search_string
      @errors        = errors
    end

    def to_s
      @search_string
    end
  end

  class SearchHandler
    attr_reader :fieldnames,
                :special_char_parser,
                :special_char_transformer,
                :quote_preparser,
                :paren_preparser,
                :field_preparser,
                :main_parser,
                :transformer


    # Create the parser from teh config
    # Note how we have to sort the search fields so the longest ones come first.
    # Otherwise, the peg parser sees 'title' and never gets to 'title_starts_with'
    def initialize(config)
      @fieldnames               = config["search_fields"].keys.sort { |a, b| b.size <=> a.size }
      @special_char_parser      = SpecialCharParser.new
      @special_char_transformer = SpecialCharTransformer.new
      @quote_preparser          = PreQueryDoubleQuotesParser.new
      @paren_preparser          = PreQueryParenthesisParser.new
      @field_preparser          = PreQueryNestedFieldsParser.new(@fieldnames)
      @main_parser              = QueryParser.new(@fieldnames)
      @fallback_parser          = FallbackParser.new
      @transformer              = QueryTransformer.new
    end

    def fix_special_chars(search)
      search_string = special_char_parser.parse(search.search_string)
      search_string = special_char_transformer.apply(search_string)
      MiniSearch.new(search_string, search.errors)
    end

    def check_quotes(search)
      search_string = search.search_string
      errors        = search.errors
      begin
        @quote_preparser.parse(search_string)
      rescue Parslet::ParseFailed
        search_string = search_string.delete("\"")
        errors << UnevenQuotesError.new(search.search_string, search_string)
      end
      MiniSearch.new(search_string, errors)
    end

    def check_parens(search)
      search_string = search.search_string
      errors        = search.errors
      begin
        @paren_preparser.parse(search_string)
      rescue Parslet::ParseFailed
        search_string = search_string.delete("()")
        errors << UnevenParensError.new(search.search_string, search_string)
      end
      MiniSearch.new(search_string, errors)
    end

    def check_nested_fields(search)
      search_string = search.search_string
      errors        = search.errors
      begin
        @field_preparser.parse(search_string)
      rescue Parslet::ParseFailed
        # The nested fields parser is only good at recognizing
        # fields that are explicitly nested using parentheses,
        # so we remove the parentheses
        any_fieldname = Regexp.union(@fieldnames)
        search_string = search_string.gsub(/(.*#{any_fieldname}):\((.*#{any_fieldname}):(.*)\)/, '\1:\2:\3')
        errors << NestedFieldsError.new(search.search_string, search_string)
      end

      # We want to eliminate nested fields like author:title:blah
      # They are unreasonably hard to recognize/prevent with Parslet
      any_fieldname = Regexp.union(@fieldnames)
      nested_regex  = /(.*#{any_fieldname}):(#{any_fieldname}):(.*)/
      match         = nested_regex.match(search_string)
      if match
        search_string = search_string.gsub(nested_regex, '\1:\2 \3')
        errors << NestedFieldsError.new(search.search_string, search_string)
      end
      MiniSearch.new(search_string, errors)
    end

    def check_parse(search)
      search_string = search.search_string
      errors        = search.errors
      begin
        @main_parser.parse(search_string)
      rescue Parslet::ParseFailed
        errors << UnparseableError.new(search_string)
      end
      MiniSearch.new(search_string, errors)
    end

    def pre_process(mini_search)
      mini_search = fix_special_chars(mini_search)

      mini_search = check_quotes(mini_search)

      mini_search = check_parens(mini_search)

      mini_search = check_nested_fields(mini_search)

      # try to actually parse! if it fails, then we add a ??? warning and throw it to solr
      mini_search = check_parse(mini_search)

      mini_search
    end

    def parse(search)
      begin
        parsed = @main_parser.parse(search)
      rescue Parslet::ParseFailed
        parsed = @fallback_parser.parse(search)
      end
      @transformer.apply(parsed)
    end
  end
end
