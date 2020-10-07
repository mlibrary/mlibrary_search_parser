module MLibrarySearchParser
  class Transform

    def initialize(confi:, **kwargs)
      @config = config
    end

    def transform(node, extras: {})
      case node.node_type
      when :search_object
        transform(node.search_tree, extras: extras)
      when :tokens
        transform_tokens_node(node, extras: extras)
      when :fielded
        transform_fielded_node(node, extras: extras)
      when :search
        transform_search_node(node, extras: extras)
      when :and
        transform_and_node(node, extras: extras)
      when :or
        transform_or_node(node, extras: extras)
      when :not
        transform_not_node(node, extras: extras)
      else
        transform_unknown_node(node, extras: extras)
      end
    end


    def transform_unknown_node(node, extras: extras)
      node.to_clean_string
    end

  end
end
