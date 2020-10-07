require_relative 'base.rb'

module MLibrarySearchParser
  module Transform
    module SolrJson
      extend Base

      module Search
        def solr_json_edismax
          search_tree.solr_json_edismax
        end
      end

      module BaseNode
        def solr_json_edismaxify(field: :allfields, extras: {})
          {
              edismax: {
                           qf: field,
                           v:  self.to_clean_string,
                           qq: self.tokens_phrase
                       }.merge(extras)
          }
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

      module TokensNode

        def solr_json_edismax(extras: {})
          solr_json_edismaxify(field: :allfields, extras: extras)
        end
      end

      module AndNode

        def solr_json_edismax(extras: {})
          if contains_fielded?
            boolnode(:must).merge(extras)
          else
            solr_json_edismaxify(extras: extras)
          end
        end
      end

      module OrNode

        def solr_json_edismax(extras: {})
          if contains_fielded?
            boolnode(:should).merge(extras)
          else
            solr_json_edismaxify(extras: extras)
          end
        end

      end

      module FieldedNode

        def solr_json_edismax(extras: {})
          query.solr_json_edismaxify(field: field, extras: extras)
        end

      end

      module SearchNode
        # can just be sent as json.query = q.solr_json_edismax.to_json
        def solr_json_edismax(extras: {})
          q = if clauses.size == 1
                clauses.first.solr_json_edismax
              else
                boolnode(:must)
              end
        end

      end
    end

    SolrJson.mix_into_base!

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