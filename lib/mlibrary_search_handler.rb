require 'json'
require 'dotenv/load'

module MLibrarySearchParser
  class UnevenParensError < RuntimeError; end

  class UnevenQuotesError < RuntimeError; end

  class NestedFieldsError < RuntimeError; end

  class UnparseableError < RuntimeError; end

  class MiniSearch
    attr_accessor :search_string, :errors, :warnings

    def initialize(search_string, errors=[])
      @search_string = search_string
      @errors = errors
    end

    def to_s
      @search_string
    end
  end

  class SearchHandler
    attr_reader :fieldnames,
      :quote_preparser,
      :paren_preparser,
      :field_preparser,
      :main_parser,
      :transformer

    def initialize(filename)
      @fieldnames = load_fieldnames(filename)
      @quote_preparser = PreQueryDoubleQuotesParser.new
      @paren_preparser = PreQueryParenthesisParser.new
      @field_preparser = PreQueryNestedFieldsParser.new(filename)
      @main_parser = QueryParser.new(filename)
      @transformer = QueryTransformer.new
    end

    def load_fieldnames(filename)
      field_file = File.read(filename)
      field_obj = JSON.parse(field_file)
      field_obj.keys
    end

    def check_quotes(search)
      search_string = search.search_string
      errors = search.errors
      begin
        @quote_preparser.parse(search_string)
      rescue Parslet::ParseFailed
        search_string = search_string.delete("\"")
        errors << UnevenQuotesError.new
      end
      MiniSearch.new(search_string, errors)
    end

    def check_parens(search)
      search_string = search.search_string
      errors = search.errors
      begin
        @paren_preparser.parse(search_string)
      rescue Parslet::ParseFailed
        search_string = search_string.delete("()")
        errors << UnevenParensError.new
      end
      MiniSearch.new(search_string, errors)
    end

    def check_nested_fields(search)
      search_string = search.search_string
      errors = search.errors
      begin
        @field_preparser.parse(search_string)
      rescue Parslet::ParseFailed
        # The nested fields parser is only good at recognizing
        # fields that are explicitly nested using parentheses,
        # so we remove the parentheses
        any_fieldname = Regexp.union(@fieldnames)
        search_string = search_string.gsub(/(.*#{any_fieldname}):\((.*#{any_fieldname}):(.*)\)/, '\1:\2:\3')
        errors << NestedFieldsError.new
      end

      # We want to eliminate nested fields like author:title:blah
      # They are unreasonably hard to recognize/prevent with Parslet
      any_fieldname = Regexp.union(@fieldnames)
      nested_regex = /(.*#{any_fieldname}):(#{any_fieldname}):(.*)/
      match        = nested_regex.match(search_string)
      if match
        search_string = search_string.gsub(nested_regex, '\1:\2 \3')
        errors << NestedFieldsError.new
      end
      MiniSearch.new(search_string, errors)
    end

    def check_parse(search)
      search_string = search.search_string
      errors = search.errors
      begin
        @main_parser.parse(search_string)
      rescue Parslet::ParseFailed
        errors << UnparseableError.new
      end
      MiniSearch.new(search_string, errors)
    end

    def pre_process(mini_search)

      mini_search = check_quotes(mini_search)

      mini_search = check_parens(mini_search)

      mini_search = check_nested_fields(mini_search)

      # try to actually parse! if it fails, then we add a ??? warning and throw it to solr
      mini_search = check_parse(mini_search)

      mini_search
    end

    def parse(search)
      parsed = @main_parser.parse(search)
      @transformer.apply(parsed)
    end
  end
end
