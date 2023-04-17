require "simplecov"
SimpleCov.start

require "yaml"
require "json"

require "bundler/setup"
require "mlibrary_search_parser/query_parser"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Set up a search builder based on the catalog
catalog_config_file = "./spec/data/00-catalog.yml"
catalog_config = YAML.load(ERB.new(File.read(catalog_config_file)).result)
CATALOG_SEARCH_BUILDER = MLibrarySearchParser::Search.search_builder(catalog_config)

def catalog_search(search_str)
  CATALOG_SEARCH_BUILDER.build(search_str)
end

def nodeify(node_or_string)
  if node_or_string.is_a? MLibrarySearchParser::Node::BaseNode
    node_or_string
  else
    MLibrarySearchParser::Node::TokensNode.new(node_or_string)
  end
end

def tnode(node_or_string)
  nodeify(node_or_string)
end

def and_node(node_or_string1, node_or_string2)
  MLibrarySearchParser::Node::AndNode.new(nodeify(node_or_string1), nodeify(node_or_string2))
end

def or_node(node_or_string1, node_or_string2)
  MLibrarySearchParser::Node::OrNode.new(nodeify(node_or_string1), nodeify(node_or_string2))
end

def fielded_node(field, node_or_string)
  MLibrarySearchParser::Node::FieldedNode.new(field, nodeify(node_or_string))
end

def not_node(node_or_string)
  MLibrarySearchParser::Node::NotNode.new(nodeify(node_or_string))
end

def search_node(*clauses)
  MLibrarySearchParser::Node::SearchNode.new(clauses.map { |c| nodeify(c) })
end
