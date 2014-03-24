# encoding: UTF-8

require 'spec_helper'

describe "Order By Clauses" do
  def with_select(statement)
    "SELECT * FROM phrases #{statement}"
  end

  def with_arel_select(statement)
    "Phrase.select(Arel.star)#{statement}"
  end

  it "works with a single column in ascending order (the default)" do
    convert(with_select("ORDER BY id")).should ==
      with_arel_select(".order(:id)")
  end

  it "works with a single qualified column in ascending order" do
    convert(with_select("ORDER BY phrases.id")).should ==
      with_arel_select(".order(Phrase.arel_table[:id])")
  end

  it "adds reverse_order call when all columns are descending" do
    convert(with_select("ORDER BY id DESC")).should ==
      with_arel_select(".order(:id).reverse_order")

    convert(with_select("ORDER BY id DESC, key DESC")).should ==
      with_arel_select(".order(:id, :key).reverse_order")
  end

  it "can handle a mix of column styles" do
    convert(with_select("ORDER BY id DESC, phrases.key DESC")).should ==
      with_arel_select(".order(:id, Phrase.arel_table[:key]).reverse_order")
  end

  it "adds individual sort types if not all columns are the same sort type" do
    convert(with_select("ORDER BY id DESC, key ASC")).should ==
      with_arel_select(".order(Phrase.arel_table[:id].desc, :key)")
  end
end