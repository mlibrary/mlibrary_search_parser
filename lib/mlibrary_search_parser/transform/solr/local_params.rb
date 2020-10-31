require_relative 'solr_search'
require 'mlibrary_search_parser/node'
require 'uri'

module MLibrarySearchParser
  module Transformer
    module Solr
      class LocalParams < SolrSearch

        def transform!
          if ["", "*"].include? original_search_tree.clean_string
            add_param("q", "*:*")
          else
            super
            add_param("q", "_query_:#{query}")

            # Need a df for the boost queries to work
            set_param('df', 'allfields')

            # merge in the defaults
            @params = solr_params.merge(@params)

          end
        end


        # @param [MLibrarySearchParser::Node::BaseNode] node
        def edismaxify(field, node)
          q_localparams_name  = "q#{node.number}"
          qq_localparams_name = "qq#{node.number}"
          tokens_name         = "t#{node.number}"

          add_param(q_localparams_name, node.clean_string)
          add_param(qq_localparams_name, lucene_escape(node.tokens_phrase))
          add_param(tokens_name, lucene_escape(node.wanted_tokens_string))

          attributes = field_config(field)
          args = attributes.keys.each_with_object({}) do  |k,h|
            v = attributes[k]
            fname = "#{field}_#{k}"
            v = v.to_s
            v = v.to_s.gsub(/\$q\b/, "$" + q_localparams_name)
            v = v.gsub(/\$qq\b/, "$" + qq_localparams_name)
            v = v.gsub(/\$t\b/, "$" + tokens_name)
            v = v.gsub(/[\n\s]+/, ' ')
            set_param(fname, v)
            h[k] = "$#{fname}"
          end

          args = default_attributes.merge(args)
          arg_pairs = args.each_pair.map{|k, v| "#{k}=#{v}"}

          "{!edismax #{arg_pairs.join(' ')} v=$#{q_localparams_name}}"
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
                MLibrarySearchParser::Node::FieldedNode.new("allfields", MLibrarySearchParser::Node::TokensNode.new("")),
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
