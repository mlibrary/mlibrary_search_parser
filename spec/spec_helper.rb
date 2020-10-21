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

def tnode(str)
  MLibrarySearchParser::Node::TokensNode.new(str)
end

def and_node(str1, str2)
  MLibrarySearchParser::Node::AndNode.new(tnode(str1), tnode(str2))
end

def or_node(str1, str2)
  MLibrarySearchParser::Node::OrNode.new(tnode(str1), tnode(str2))
end

def fielded_node(str)
  MLibrarySearchParser::Node::FieldedNode.new("title", tnode(str))
end

def not_node(str)
  MLibrarySearchParser::Node::NotNode.new(str)
end