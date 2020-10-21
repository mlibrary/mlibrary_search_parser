# frozen_string_literal: true
module MLibrarySearchParser::Node
  # The base of all the node types. Has everything you need
  # for inspecting and traversing the tree
  class BaseNode
    attr_accessor :parent

    def set_parent!(parent)
      @parent = parent
      self
    end

    # @abstract What type of node is this?
    # @return [Symbol] Symbol representing the node type
    def node_type
      raise "#{self.class} needs to implement node_type"
    end

    # Perform a deep duplication (creating new objects for
    # both self and stuff contained in self), applying
    # the block (if given) to each node as it's duplicated
    # @abstract
    # @return [BaseNode]
    def deep_dup(&blk)
      raise "#{self.class} needs to implement deep_dup(&blk)"
    end

    # Is this the given type?
    # @param [Symbol] type the node type to detect
    # @return [Boolean]
    def is_type?(type)
      node_type == type.to_sym
    end

    # Put parentheses around a string iff it includes
    # spaces and isn't already surrounded by parens
    # @param [String] s The string to maybe parenthesize
    def parenthesize_multiwords(s)
      if s.match(/\s/) and !s.match(/\A\(.*\)\Z/)
        "(#{s})"
      else
        s
      end
    end

    # Produce a "clean string" without too many extra parens and such
    # Default implementation just returns the string with optional
    # parens
    # @return [String] the clean string representation of the subtree
    def to_clean_string
      parenthesize_multiwords(to_s)
    end

    # Is this the root node?
    def root_node?
      parent.nil?
    end

    # Get the immediate children -- nothing for leaves, left/right
    # for boolean, operand for unary, or all the clauses for a
    # multi-clause
    # @see #descendants to get all descendants
    # @return [Array<BaseNode>] The child nodes
    def children
      []
    end

    # Get all the descendants (not including self) as a flat
    # list of nodes, depth-first
    # @return [Array<BaseNode>]
    def descendants
      children.flat_map(&:flatten)
    end

    # Flat list of all nodes in the subtree rooted by this
    # node, including self
    # @return [Array<BaseNode>]
    def flatten
      descendants.unshift(self)
    end

    # Flat list of all ancestors, or the empty list
    # if this is the root node
    # @return [Array<BaseNode>]
    def ancestors
      if root_node?
        []
      else
        [parent].concat parent.ancestors
      end
    end

    # Trim off any subtrees that fulfill the
    # (boolean-returning) block given
    # @yieldparam [BaseNode] self
    # @return [BaseNode, EmptyNode] self with any matching subtrees removed,
    # or an EmptyNode if self matched
    def trim(&blk)
      if blk.call(self)
        EmptyNode.new
      else
        self
      end
    end

    # Trim off the NOT clauses
    def trim_not
      trim { |n| n.is_type?(:not) }
    end

    # Is the current node an ancestor of a fielded node?
    # Useful for determining when to add parens and whether
    # there are weirdnesses in how fielded searches are nested
    # @return [Boolean]
    def contains_fielded?
      children.any? { |c| c.is_type?(:fielded) or c.contains_fielded? }
    end

    # Is the current node a descendant of a fielded node?
    # @return [Boolean]
    def in_fielded?
      ancestors.any? { |n| n.is_type?(:fielded) }
    end

    # When determining how to construct a search string, it's
    # useful to get a list of child nodes that are "positive"
    # (things we want to find) or "negative" (things we want
    # to reject). #children is useful in this case because it
    # generically gets all the clauses, the left/right of a
    # boolean, and the operand of a unary.
    # @return [Array<BaseNode>]
    def positives
      children.reject{|x| x.is_type?(:not)}
    end

    # @see positives
    def negatives
      children.select{|x| x.is_type?(:not)}.map(&:operand)
    end

    # Get a depth-first list of all nodes in the current subtree (including self)
    # that return true for the given block
    # @yieldparam self
    # @yieldreturn [Boolean]
    # @return [Array<BaseNode>]
    def select(&blk)
      flatten.select { |n| blk.call(n) }
    end

    # Select, for the given type
    def select_type(type)
      select { |x| x.is_type?(type.to_sym) }
    end

    # Get a string joining all the tokens in the normal
    # left-to-right -- essentially, the search without any
    # booleans/fields/etc, and skipping any empty strings
    # @return [String]
    def tokens_string
      select_type(:tokens).map(&:to_s).reject { |str| str.empty? }.join(" ")
    end

    # The tokens_string, but devoid of double-quotes and then wrapped
    # in new double-quotes
    def tokens_phrase
      %Q("#{tokens_string.gsub('"', '')}")
    end
  end
end
