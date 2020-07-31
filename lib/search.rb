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
    attr_accessor :errors, :warnings, :search_tree, :original_input
    # could come from search box, from adv search form, or from solr output

    def initialize(original_input)
      @original_input = original_input
      search_handler = SearchHandler.new('spec/data/fields_file.json')
      mini_search = search_handler.pre_process(original_input)
      @search_tree = search_handler.parse(mini_search.to_s)
    end

    def valid?
      true
    end

    def errors?
      false
    end

    def warnings?
      false
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
      search_tree.to_s
    end
  end
end
