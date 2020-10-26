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
        def edismaxify(field, node)
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

        def not_node(node)
          "NOT (#{transform(node.operand)})"
        end

        def search_node(node)
          super
        end

        # We need to special-case a lone "NOT" because solr doesn't seem to accept
        # a query of the form __query__:NOT {!edismax...}
        #
        # To do this, make a blank query against the allfields by constructing a
        # TokensNode with an empty-string. This will never happen via a normal parse.
        def search_node(node)
          first = node.clauses.first
          if node.clauses.size == 1 and first.is_type?(:not)
            fake_and = (MLibrarySearchParser::Node::AndNode.new(
                MLibrarySearchParser::Node::TokensNode.new(""),
                first
            ))
            fake_and.renumber!
            transform(fake_and)
          else
            super(node)
          end
        end


      end
    end
  end
end
