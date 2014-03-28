# encoding: UTF-8

require 'spec_helper'

describe "Order By Clauses" do
  def with_select(statement)
    "SELECT * FROM phrases ORDER BY #{statement}"
  end

  def with_arel_select(statement)
    "Phrase.select(Arel.star)#{statement}"
  end

  it "works with a single column in ascending order (the default)" do
    convert(with_select("id")).should ==
      with_arel_select(".order(:id)")
  end

  it "works with a single qualified column in ascending order" do
    convert(with_select("phrases.id")).should ==
      with_arel_select(".order(Phrase.arel_table[:id])")
  end

  it "adds reverse_order call when all columns are descending" do
    convert(with_select("id DESC")).should ==
      with_arel_select(".order(:id).reverse_order")

    convert(with_select("id DESC, key DESC")).should ==
      with_arel_select(".order(:id, :key).reverse_order")
  end

  it "can handle a mix of column styles" do
    convert(with_select("id DESC, phrases.key DESC")).should ==
      with_arel_select(".order(:id, Phrase.arel_table[:key]).reverse_order")
  end

  it "adds individual sort types if not all columns are the same sort type" do
    convert(with_select("id DESC, key ASC")).should ==
      with_arel_select(".order(Phrase.arel_table[:id].desc, :key)")
  end

  it "works with function calls" do
    convert(with_select("STRLEN(key)")).should ==
      with_arel_select(".order(Arel::Nodes::NamedFunction.new('STRLEN', [:key]))")
  end

  it "works with nested function calls where one is an aggregate" do
    convert(with_select("STRLEN(COUNT(phrases.key))")).should ==
      with_arel_select(".order(Arel::Nodes::NamedFunction.new('STRLEN', [Phrase.arel_table[:key].count]))")
  end

  it "works with nested function calls" do
    convert(with_select("COALESCE(STRLEN(key), 'abc')")).should ==
      with_arel_select(".order(Arel::Nodes::NamedFunction.new('COALESCE', [Arel::Nodes::NamedFunction.new('STRLEN', [:key]), 'abc']))")
  end
end