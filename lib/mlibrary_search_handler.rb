require 'json'
require 'dotenv/load'

module MLibrarySearchParser
  class UnevenParensError < RuntimeError; end

  class UnevenQuotesError < RuntimeError; end

  class NestedFieldsError < RuntimeError; end

  class SearchHandler
    attr_reader :fieldnames

    def initialize()
      @fieldnames = load_fieldnames(ENV["FIELDS_FILE"])
    end

    def load_fieldnames(filename)
      field_file = File.read(filename)
      field_obj = JSON.parse(field_file)
      field_obj.keys
    end

    def pre_process(search)
      @errors = []
      begin
        PreQueryDoubleQuotesParser.new.parse(search)
      rescue Parslet::ParseFailed
        search = search.delete("\"")
        @errors << UnevenQuotesError.new
      end

      begin
        PreQueryParenthesisParser.new.parse(search)
      rescue Parslet::ParseFailed
        search = search.delete("()")
        @errors << UnevenParensError.new
      end

      begin
        PreQueryNestedFieldsParser.new.parse(search)
      rescue Parslet::ParseFailed
        # The nested fields parser is only good at recognizing
        # fields that are explicitly nested using parentheses,
        # so we remove the parentheses
        search = search.gsub(/(.*):\((.*):(.*)\)/, '\1:\2:\3')
        @errors << NestedFieldsError.new
      end

      # We want to eliminate nested fields like author:title:blah
      # They are unreasonably hard to recognize/prevent with Parslet
      any_fieldname = Regexp.union(@fieldnames)
      nested_regex = /(.*#{any_fieldname}):(#{any_fieldname}):(.*)/
      match        = nested_regex.match(search)
      if match
        search = search.gsub(nested_regex, '\1:\2 \3')
        @errors << NestedFieldsError.new
      end
      search
    end
  end
end
