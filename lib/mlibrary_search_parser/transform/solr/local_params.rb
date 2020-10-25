require_relative 'solr_search'
require 'mlibrary_search_parser/node'
require 'uri'

module MLibrarySearchParser
  module Transformer
    module Solr
      class LocalParams < SolrSearch

        def transform!
          super
          add_param("q", "_query_:#{query}")
        end

        # @param [MLibrarySearchParser::Node::BaseNode] node
        def edismaxify(node)
          field = node.is_type?(:fielded) ? node.field : @config['search_field_default']

          q_localparams_name  = "q#{node.number}"
          qq_localparams_name = "qq#{node.number}"

          add_param(q_localparams_name, node.clean_string)
          add_param(qq_localparams_name, node.tokens_phrase)

          args = field_config(field).each_pair.map do |k, v|
            v = v.to_s.gsub(/\$q\b/, q_localparams_name)
            v = v.gsub(/\$qq\b/, qq_localparams_name)
            v = v.gsub(/[\n\s]+/, ' ')
            "#{k}=\"#{v}\""
          end
          "{!edismax #{args.join(' ')} v=$#{q_localparams_name}}"
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
