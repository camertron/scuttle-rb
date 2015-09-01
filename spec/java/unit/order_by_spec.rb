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
    expect(convert(with_select("id"))).to eq(
      with_arel_select(".order(:id)")
    )
  end

  it "works with a single qualified column in ascending order" do
    expect(convert(with_select("phrases.id"))).to eq(
      with_arel_select(".order(Phrase.arel_table[:id])")
    )
  end

  it "adds reverse_order call when all columns are descending" do
    expect(convert(with_select("id DESC"))).to eq(
      with_arel_select(".order(:id).reverse_order")
    )

    expect(convert(with_select("id DESC, key DESC"))).to eq(
      with_arel_select(".order(:id, :key).reverse_order")
    )
  end

  it "can handle a mix of column styles" do
    expect(convert(with_select("id DESC, phrases.key DESC"))).to eq(
      with_arel_select(".order(:id, Phrase.arel_table[:key]).reverse_order")
    )
  end

  it "adds individual sort types if not all columns are the same sort type" do
    expect(convert(with_select("phrases.id DESC, phrases.key ASC"))).to eq(
      with_arel_select(".order(Phrase.arel_table[:id].desc, Phrase.arel_table[:key])")
    )
  end

  it "works with function calls" do
    expect(convert(with_select("STRLEN(key)"))).to eq(
      with_arel_select(".order(Arel::Nodes::NamedFunction.new('STRLEN', [:key]))")
    )
  end

  it "works with aggregate function calls (value expressions)" do
    expect(convert(with_select("COUNT(phrases.key)"))).to eq(
      with_arel_select(".order(Phrase.arel_table[:key].count)")
    )
  end

  it "works with nested function calls where one is an aggregate" do
    expect(convert(with_select("STRLEN(COUNT(phrases.key))"))).to eq(
      with_arel_select(".order(Arel::Nodes::NamedFunction.new('STRLEN', [Phrase.arel_table[:key].count]))")
    )
  end

  it "works with nested function calls" do
    expect(convert(with_select("COALESCE(STRLEN(key), 'abc')"))).to eq(
      with_arel_select(".order(Arel::Nodes::NamedFunction.new('COALESCE', [Arel::Nodes::NamedFunction.new('STRLEN', [:key]), 'abc']))")
    )
  end
end