# encoding: UTF-8

require 'pathname'
require 'coderay'
require 'java'

require Pathname(__FILE__).dirname.dirname.join("vendor/jars/Scuttle.jar").to_s

java_import 'com.camertron.Scuttle.SqlStatementVisitor'
java_import 'com.camertron.Scuttle.ScuttleOptions'
java_import 'com.camertron.Scuttle.Resolver.AssociationManager'
java_import 'com.camertron.Scuttle.Resolver.AssociationType'
java_import 'com.camertron.SQLParser.SQLLexer'
java_import 'com.camertron.SQLParser.SQLParser'
java_import 'org.antlr.v4.runtime.ANTLRInputStream'
java_import 'org.antlr.v4.runtime.CharStream'
java_import 'org.antlr.v4.runtime.CommonTokenStream'

module Scuttle
  class ScuttleConversionError < StandardError; end

  class << self

    MAX_CHARS = 50

    def convert(sql_string, options = {}, assoc_manager)
      input = ANTLRInputStream.new(sql_string)
      lexer = SQLLexer.new(input)
      tokens = CommonTokenStream.new(lexer)
      parser = SQLParser.new(tokens)
      options = scuttle_options_from(options)
      visitor = SqlStatementVisitor.new(assoc_manager.createResolver, options)
      visitor.visit(parser.sql)
      visitor.toString
    rescue => e
      puts e.message
      puts e.backtrace
      raise ScuttleConversionError, 'Scuttle parser error, check your SQL syntax.'
    end

    def beautify(str)
      format(parse(str), 0)
    end

    def colorize(str, encoder = :terminal)
      enc = CodeRay.encoder(encoder)
      enc.encode(str, :ruby)
    end

    private

    def scuttle_options_from(options)
      ScuttleOptions.new.tap do |scuttle_options|
        scuttle_options.useArelHelpers(options.fetch(:use_arel_helpers, false))
        scuttle_options.useArelNodesPrefix(options.fetch(:use_arel_nodes_prefix, true))
      end
    end

    def parse(str)
      tokens = str.split(/([\[\]()])/)
      consumed, children = build_tree(tokens, 0)
      Node.new(children + tokens[consumed..(tokens.size - 1)])
    end

    def build_tree(tokens, index)
      children = []
      i = index

      while(i < tokens.size)
        token = tokens[i]

        if node_class = open_class(token)
          consumed, recursive_children = build_tree(tokens, i + 1)
          children << node_class.new(recursive_children)
          i += consumed
        elsif is_close?(token)
          i += 1
          break
        else
          children << token
        end

        i += 1
      end

      [i - index, children]
    end

    def format(root, level)
      case root
        when String
          root
        when ParenthesizedNode, BracketedNode
          start = root.open_char
          middle = root.children.map { |child| format(child, level + 1) }.join
          finish = root.close_char

          if (start.size + middle.size + finish.size) > MAX_CHARS
            "#{start}\n#{indent_for(level + 1)}#{middle}\n#{indent_for(level)}#{finish}"
          else
            "#{start}#{middle}#{finish}"
          end
        when Node
          root.children.map { |child| format(child, level) }.join
      end
    end

    Node = Struct.new(:children) do
      def to_s
        children.map(&:to_s).join
      end
    end

    ParenthesizedNode = Class.new(Node) do
      def to_s
        "(#{super})"
      end

      def open_char
        @open_char ||= "("
      end

      def close_char
        @close_char ||= ")"
      end
    end

    BracketedNode = Class.new(Node) do
      def to_s
        "[#{super}]"
      end

      def open_char
        @open_char ||= "["
      end

      def close_char
        @close_char ||= "]"
      end
    end

    def indent_for(level)
      "  " * level
    end

    def open_class(str)
      case str
        when "("
          ParenthesizedNode
        when "["
          BracketedNode
      end
    end

    def is_close?(str)
      case str
        when ")", "]"
          true
        else
          false
      end
    end

    def is_pair?(open, close)
      (open == "(" && close == ")") ||
        (open == "[" && close == "]")
    end

  end
end
