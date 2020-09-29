module MLibrarySearchParser
  module Transform
    INCLUDABLES = %w[BaseNode BinaryNode TokensNode UnaryNode AndNode OrNode NotNode FieldedNode SearchNode]

    module SolrJson

      def self.mix_into_base!
        INCLUDABLES.each do |klassname|
          baseclass = MLibrarySearchParser::Node.const_get(klassname)
          baseclass.include self.const_get(klassname)
        end
      end

      module BaseNode
        def edismaxify(field: :allfields, extras: {})
          {
              edismax: {
                           qf: field,
                           v:  self.to_clean_string,
                           qq: self.tokens_phrase
                       }.merge(extras)
          }
        end

        def negatives
          children.select(&:not_node?).map(&:operand)
        end

        def positives
          children.reject(&:not_node?)
        end

        # Create a bool node where the "positive" (non-negated) items go into the should/must,
        # and the negated clauses go into the must_not
        # @todo Deal with double-negation
        def boolnode(shouldmust)
          q = {
              bool: {shouldmust.to_sym => positives.map(&:solr_json_edismax)}
          }
          if negatives.size > 0
            q[:bool][:must_not] = negatives.map(&:solr_json_edismax)
          end
          q
        end

      end

      module BinaryNode

      end

      module TokensNode

        def solr_json_edismax(extras: {})
          edismaxify(field: :allfields, extras: extras)
        end
      end

      module UnaryNode

      end

      module AndNode

        def solr_json_edismax(extras: {})
          if contains_fielded?
            boolnode(:must).merge(extras)
          else
            edismaxify(extras: extras)
          end
        end
      end

      module OrNode

        def solr_json_edismax(extras: {})
          if contains_fielded?
            boolnode(:should).merge(extras)
          else
            edismaxify(extras: extras)
          end
        end

      end

      module NotNode

      end


      module FieldedNode

        def solr_json_edismax(extras: {})
          query.edismaxify(field: field, extras: extras)
        end

      end

      module SearchNode
        def solr_json_edismax(extras: {})
          q = if clauses.size == 1
                clauses.first.solr_json_edismax
              else
                boolnode(:must)
              end
          if self.root_node?
            {query: q}
          else
            q
          end
        end

      end
    end

  end
end


#
#     # @param [MLibrarySearchParser::Node::BaseNode] search
#     def initialize(search)
#       @search = search
#     end
#
#     # A tokens node is just itself as a string
#     def transform_text(tokensnode)
#       tokensnode.to_clean_string
#     end
#
#     # A node -- no matter how deep -- can be sent to edismax
#     # just as our standard clean text representation
#     # if it doesn't have any embedded fieldeds
#     def transform_unfielded_tree(node)
#       node.to_clean_string
#     end
#
#     # @param [String,Symbol] field The (abstract) field name
#     # @param [MLibrarySearchParser::Node::BaseNode] node
#     def edismax(field: :allfields, node:)
#       {
#           edismax: {
#               qf: field,
#               v: node.to_clean_string,
#               qq: node.tokens_phrase
#           }
#       }
#     end
#
#
#
#     def transform_fielded(node)
#       edismax(field: node.field, node: node)
#     end
#
#
#
#
#
#
#   end
# end