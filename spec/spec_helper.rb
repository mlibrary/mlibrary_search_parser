require "bundler/setup"
require "mlibrary_search_parser"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def nodeify(node_or_string)
  if node_or_string.kind_of? MLibrarySearchParser::Node::BaseNode
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

def fielded_node(node_or_string)
  MLibrarySearchParser::Node::FieldedNode.new("title", nodeify(node_or_string))
end

def not_node(node_or_string)
  MLibrarySearchParser::Node::NotNode.new(nodeify(node_or_string))
end