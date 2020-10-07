require 'mlibrary_search_parser/node/search'
require 'mlibrary_search_parser/node/fielded'
require 'mlibrary_search_parser/node/boolean'
require 'search'


module MLibrarySearchParser
  module Transform
    module SolrLocalParams
      extend Base


      module Search
        def solr_local_params_edismax(extras: {})
          search_tree.local_params_edismax.merge(extras)
        end
      end

      module BaseNode
        def solr_local_params_edismaxify
      end

      module SearchNode; end




      module BinaryNode;end
      module TokensNode; end
      module UnaryNode; end
      module AndNode; end
      module OrNode; end
      module NotNode; end
      module FieldedNode; end

    end
    SolrLocalParams.mix_into_base!

  end
end
