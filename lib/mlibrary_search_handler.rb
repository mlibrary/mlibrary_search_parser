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
      search
    end
  end
end
