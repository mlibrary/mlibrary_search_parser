<<<<<<< HEAD
require "mlibrary_search_parser/search_handler"
=======
require 'mlibrary_search_parser/search_handler'
require "delegate"
>>>>>>> c310bd04aa780cdc5f3be5c30317f64915c419dd

module MLibrarySearchParser
  class SearchBuilder
    attr_accessor :config

    def initialize(config)
      @config = config
    end

    def build(original_input)
      Search.new(original_input, config)
    end
  end

  class Search < SimpleDelegator

    attr_reader :original_input, :mini_search, :config, :errors, :warnings

    # could come from search box, from adv search form, or from solr output
    def self.from_form(input, search_handler)
    end

    def self.search_builder(config)
      SearchBuilder.new(config)
    end

    def initialize(original_input, config)
      @original_input = original_input
      @config = config
      @search_handler = MLibrarySearchParser::SearchHandler.new(@config)
      @mini_search = @search_handler.pre_process(MiniSearch.new(original_input))
      @errors = Array(@mini_search.errors)
      @warnings = Array(@mini_search.warnings)
      @search_tree = @search_handler.parse(mini_search.to_s)
      __setobj__(@search_tree)
    end

    def clean_string
      search_tree.clean_string
    end

    def search_tree
      @search_tree ||= @search_handler.parse(mini_search.to_s)
    end

    def shake
      @search_tree = search_tree.shake
    end

    def valid?
      !errors? or warnings?
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

    def to_solr_query
      # the string to give to solr
      # producing a complicated highly specific solr query
      # with edismax stuff and lists of fields and all that
      search_tree.to_s
    end
  end
end
