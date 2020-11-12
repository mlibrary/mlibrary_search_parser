require 'mlibrary_search_parser/search_handler'

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
      operators   = []
      input_form.each { |node|
        case node.keys.first
        when "fielded"
          field        = node["fielded"]["field"]
          query        = node["fielded"]["query"]
          @config_file = './spec/data/00-catalog.yml'
          @config      = YAML.load(ERB.new(File.read(@config_file)).result)
          query_search = Search.new(query, @config)
          field_node   = MLibrarySearchParser::Node::FieldedNode.new(field, query_search.search_tree)
          field_nodes.push(field_node)
        when "operator"
          operators.push(node["operator"])
        end
      }
      operators.reduce(field_nodes.shift) { |root, new_oper|
        MLibrarySearchParser::Node::Boolean.for_operator(new_oper,
                                                         root,
                                                         field_nodes.shift)
      }
    end

    def to_s
      search_tree.to_s
    end
  end

  class SearchBuilder
    attr_accessor :config

    def initialize(config)
      @config = config
    end

    def build(original_input)
      Search.new(original_input, config)
    end
  end

  class AdvancedSearchBuilder < SearchBuilder
    # array of {field: blah, query: blah, booleanType: blah}
    # where booleanType is an index into [AND, OR, NOT]

    def build(search_form)
      input = ""
      search_form.each_with_index { |e, i|
        field = e[:field]
        query = e[:query]
        input += "#{field}:(#{query})"
        if search_form[i+1] and search_form[i+1][:query] != ""
          bool = case e[:booleanType]
                 when 0
                   "AND"
                 when 1
                   "OR"
                 when 2
                   "NOT"
                 end
          input += " #{bool} "
        end
      }
      Search.new(input, config)
    end
  end

  class Search
    attr_reader :search_tree, :original_input, :mini_search, :config
    # could come from search box, from adv search form, or from solr output

    def self.from_form(input, search_handler) end

    def self.search_builder(config)
      SearchBuilder.new(config)
    end

    def initialize(original_input, config)
      @original_input = original_input
      @config         = config
      @search_handler = MLibrarySearchParser::SearchHandler.new(@config)
      @mini_search    = @search_handler.pre_process(MiniSearch.new(original_input))
    end

    def clean_string
      search_tree.clean_string
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
