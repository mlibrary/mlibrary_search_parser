module MLibrarySearchParser
  class SearchHandler
    def pre_process(search)
      begin
        PreQueryParenthesisParser.new.parse(search)
      rescue Parslet::ParseFailed
        search = search.delete("()")
      end

      begin
        PreQueryDoubleQuotesParser.new.parse(search)
      rescue Parslet::ParseFailed
        search = search.delete("\"")
      end

      begin
        PreQueryNestedFieldsParser.new.parse(search)
      rescue Parslet::ParseFailed
        # The nested fields parser is only good at recognizing
        # fields that are explicitly nested using parentheses,
        # so we remove the parentheses
        search = search.gsub(/(.*):\((.*):(.*)\)/, '\1:\2:\3')
      end

      # We want to eliminate nested fields like author:title:blah
      # They are unreasonably hard to recognize/prevent with Parslet
      search = search.gsub(/(.*):([^\s]*):(.*)/, '\1:\2 \3')
      search
    end
  end
end
