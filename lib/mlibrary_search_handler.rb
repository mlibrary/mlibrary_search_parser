module MLibrarySearchParser
  class UnevenParensError < RuntimeError; end

  class UnevenQuotesError < RuntimeError; end

  class NestedFieldsError < RuntimeError; end

  class SearchHandler
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
      nested_regex = /(.*):([^\s]*):(.*)/
      match        = nested_regex.match(search)
      if match
        search = search.gsub(/(.*):([^\s]*):(.*)/, '\1:\2 \3')
        @errors << NestedFieldsError.new
      end
      search
    end
  end
end
