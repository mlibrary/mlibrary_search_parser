# frozen_string_literal: true

require 'mlibrary_search_parser/node'

module MLibrarySearchParser
  module Transform
    # A generic structure on which to build transforms if you like.
    # It basically does nothing but provide a simple initializer
    # and a method #transform to dispatch to canonically-named
    # node tranformation methods based n the node type
    class Base

      attr_accessor :config
      
      # Simplest possible intializer
      def initialize(config:, **kwargs)
        @config = config
      end

      # Dispatch to specific methods for transforming
      # each node type
      # @param [MLibrarySearchParser::Node::BaseNode] node
      # @return [??] depends on that transformation being done
      def transform(node)
        case node.node_type
        when :search_object
          transform(node.search_tree, extras: extras)
        when :tokens
          tokens_node(node, extras: extras)
        when :fielded
          fielded_node(node, extras: extras)
        when :search
          search_node(node, extras: extras)
        when :and
          and_node(node, extras: extras)
        when :or
          or_node(node, extras: extras)
        when :not
          not_node(node, extras: extras)
        else
          unknown_node(node, extras: extras)
        end
      end


      def unknown_node(node, extras: {})
        node.to_clean_string.downcase
      end

    end
  end
end 