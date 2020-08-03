require 'mlibrary_search_handler'

module MLibrarySearchParser
  # class SearchFactory
  #   def initialize(config)
  #   end

  #   def raw_string_search(string)
  #   end

  #   def webform_search(form_fields)
  #     # imagining form_fields to look something like:
  #     # [
  #     # "field": "all_fields",
  #     # "query": "blah blah",
  #     # "operator": "AND",
  #     # "field": "title",
  #     # "query": "bler bleh"
  #     # ]
  #     # that is, an ordered list of key/value pairs
  #   end
  # end

  class Search
    attr_reader :search_tree, :original_input, :mini_search
    # could come from search box, from adv search form, or from solr output

    def initialize(original_input, search_handler)
      @original_input = original_input
      @search_handler = search_handler
      @mini_search = @search_handler.pre_process(MiniSearch.new(original_input))
    end

    def search_tree
      @search_tree ||= @search_handler.parse(mini_search.to_s)
    end

    def valid?
      not errors? or warnings?
    end

    def errors
      Array(mini_search.errors)
    end

    def warnings
      Array(mini_search.warnings)
    end

    def errors?
      errors.any?
    end

    def warnings?
      warnings.any?
    end

    def to_s
      # the string to put back in the search box
      search_tree.to_s
    end

    def to_webform
      # might return an ordered list of duples
      search_tree.to_webform
    end

    def to_solr_query
      # the string to give to solr
      # producing a complicated highly specific solr query
      # with edismax stuff and lists of fields and all that
      search_tree.to_s
    end
  end
end
