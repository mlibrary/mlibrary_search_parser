require_relative 'json_edismax'
require 'uri'

module MLibrarySearchParser
  module Transformer
    module Solr
      class LocalParams < JsonEdismax

        # @override
        def edismaxify(node, field: :allfields, extras: {}, escape: false)
          v = URI.encode_www_form_component(lucene_escape_node(node).to_clean_string)
          v = lucene_escape_node(node).to_clean_string
          "{!edismax qf=\"#{field}\" v=\"#{v}\"}"
        end


        # @override
        def boolnode(node, shouldmust)

          joiner = if shouldmust == :must
                     "AND"
                   elsif shouldmust == :should
                     "OR"
                   else
                     raise "ShouldMust should only get :should or :must"
                   end
          "(#{transform(node.left)} #{joiner} #{transform(node.right)})"
        end

        def transform_not_node(node, extras: {})
          "NOT (#{transform(node)})"
        end

      end
    end
  end
end
