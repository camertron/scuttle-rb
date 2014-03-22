# encoding: UTF-8

require 'pathname'
require 'java'

require Pathname(__FILE__).dirname.dirname.join("vendor/jars/Scuttle.jar").to_s

java_import 'com.camertron.Scuttle.SqlStatementVisitor'
java_import 'com.camertron.SQLParser.SQLLexer'
java_import 'com.camertron.SQLParser.SQLParser'
java_import 'org.antlr.v4.runtime.ANTLRInputStream'
java_import 'org.antlr.v4.runtime.CharStream'
java_import 'org.antlr.v4.runtime.CommonTokenStream'

module Scuttle
  class << self

    def convert(sql_string)
      input = ANTLRInputStream.new(sql_string)
      lexer = SQLLexer.new(input)
      tokens = CommonTokenStream.new(lexer)
      parser = SQLParser.new(tokens)
      visitor = SqlStatementVisitor.new
      visitor.visit(parser.sql)
      visitor.toString
    end

  end
end