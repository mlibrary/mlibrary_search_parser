require 'mlibrary_search_parser/node/search'
require 'mlibrary_search_parser/node/fielded'
require 'mlibrary_search_parser/node/boolean'
require 'search'


module MLibrarySearchParser
  module Transform
    module Base
      NodeClasses = %w[BaseNode BinaryNode TokensNode UnaryNode AndNode OrNode NotNode FieldedNode SearchNode]

      def mix_into_base!
        NodeClasses.each do |klassname|
          baseclass = MLibrarySearchParser::Node.const_get(klassname)
          if self.const_defined?(klassname)
            baseclass.include self.const_get(klassname)
          end
        end

        MLibrarySearchParser::Search.include self.const_get('Search')
      end
    end
  end
end

