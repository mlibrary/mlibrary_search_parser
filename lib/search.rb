# frozen_string_literal: true

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

  class WebformParser
    attr_reader :input_form

    def initialize(input_form)
      @input_form = input_form
    end

    # given something like this:
    # [ {"fielded" => {"field" => "title", "query" => "something"}},
    # {"operator" => "OR"},
    # etc ]
    # run each subquery through the search handler, then build FieldedNodes,
    # then build Boolean nodes, then stick em all together

    def search_tree
      field_nodes = []
      operators = []
      input_form.each do |node|
        case node.keys.first
        when "fielded"
          field = node["fielded"]["field"]
          query = node["fielded"]["query"]
          query_search = Search.new(query, MLibrarySearchParser::SearchHandler.new('spec/data/fields_file.json'))
          field_node = MLibrarySearchParser::Node::FieldedNode.new(field, query_search.search_tree)
          field_nodes.push(field_node)
        when "operator"
          operators.push(node["operator"])
        end
      end
      operators.reduce(field_nodes.shift) do |root, new_oper|
        MLibrarySearchParser::Node::Boolean.for_operator(
          new_oper,
          root,
          field_nodes.shift
        )
      end
    end

    def to_s
      search_tree.to_s
    end
  end

  class Search
    attr_reader :search_tree, :original_input, :mini_search
    # could come from search box, from adv search form, or from solr output

    def self.from_form(input, search_handler); end

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
