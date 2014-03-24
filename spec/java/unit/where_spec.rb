# encoding: UTF-8

require 'spec_helper'

describe "Where Clauses" do
  def with_select(statement)
    "SELECT * FROM phrases #{statement}"
  end

  def with_arel_select(statement)
    "Phrase.select(Arel.star).where(#{statement})"
  end

  it "works with a single literal" do
    convert(with_select("WHERE 1")).should == with_arel_select("1")
  end

  it "wraps literals that are the first operands in an expression" do
    convert(with_select("WHERE 1 = 1")).should ==
      with_arel_select("Arel::Nodes::SqlLiteral.new('1').eq(1)")
  end

  # we need better handling of non-qualified columns to make this test pass
  it "works with a column name on the left-hand side of an expression" # do
  #   convert(with_select("WHERE id = 1")).should ==
  #     with_arel_select("Phrase.arel_table[:id].eq(1)")
  # end

  it "works with a qualified column name on the left-hand side of an expression" do
    convert(with_select("WHERE phrases.id = 1")).should ==
      with_arel_select("Phrase.arel_table[:id].eq(1)")
  end

  it "works with a column name on the right-hand side of an expression" do
    convert(with_select("WHERE 1 = phrases.id")).should ==
      with_arel_select("Arel::Nodes::SqlLiteral.new('1').eq(Phrase.arel_table[:id])")
  end

  it "works with column names on both sides of an expression" do
    convert(with_select("WHERE phrases.key = phrases.meta_key")).should ==
      with_arel_select("Phrase.arel_table[:key].eq(Phrase.arel_table[:meta_key])")
  end

  it "works with inequality operators with two columns" do
    convert(with_select("WHERE phrases.key > phrases.meta_key")).should ==
      with_arel_select("Phrase.arel_table[:key].gt(Phrase.arel_table[:meta_key])")

    convert(with_select("WHERE phrases.key < phrases.meta_key")).should ==
      with_arel_select("Phrase.arel_table[:key].lt(Phrase.arel_table[:meta_key])")

    convert(with_select("WHERE phrases.key >= phrases.meta_key")).should ==
      with_arel_select("Phrase.arel_table[:key].gteq(Phrase.arel_table[:meta_key])")

    convert(with_select("WHERE phrases.key <= phrases.meta_key")).should ==
      with_arel_select("Phrase.arel_table[:key].lteq(Phrase.arel_table[:meta_key])")
  end

  it "works with inequality operators with columns and literals" do
    convert(with_select("WHERE phrases.key > 1")).should ==
      with_arel_select("Phrase.arel_table[:key].gt(1)")

    convert(with_select("WHERE phrases.key < 2")).should ==
      with_arel_select("Phrase.arel_table[:key].lt(2)")

    convert(with_select("WHERE phrases.key >= 3")).should ==
      with_arel_select("Phrase.arel_table[:key].gteq(3)")

    convert(with_select("WHERE phrases.key <= 4")).should ==
      with_arel_select("Phrase.arel_table[:key].lteq(4)")
  end

  it "works with a basic AND" do
    convert(with_select("WHERE phrases.key = 'abc' AND phrases.id = 22")).should ==
      with_arel_select("Phrase.arel_table[:key].eq('abc').and(Phrase.arel_table[:id].eq(22))")
  end

  it "works with a basic OR" do
    convert(with_select("WHERE phrases.key = 'abc' OR phrases.id = 22")).should ==
      with_arel_select("Phrase.arel_table[:key].eq('abc').or(Phrase.arel_table[:id].eq(22))")
  end

  it "works with chained ANDs and ORs" do
    convert(with_select("WHERE phrases.key = 'abc' AND (phrases.id = 22 OR phrases.id = 109)")).should ==
      with_arel_select("Phrase.arel_table[:key].eq('abc').and(Phrase.arel_table[:id].eq(22).or(Phrase.arel_table[:id].eq(109)))")
  end

  it "works with a simple IN list" do
    convert(with_select("WHERE phrases.id IN (1, 2, 3, 4)")).should ==
      with_arel_select("Phrase.arel_table[:id].in(1, 2, 3, 4)")
  end

  it "works with an IN that contains a select statement" do
    convert(with_select("WHERE phrases.id IN (SELECT id FROM phrases WHERE 1)")).should ==
      with_arel_select("Phrase.arel_table[:id].in(Phrase.select(:id).where(1).ast)")
  end
end
