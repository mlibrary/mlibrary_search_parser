# frozen_string_literal: true

require "mlibrary_search_parser/node"

module MLibrarySearchParser
  module Transformer
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
    end
  end
end
