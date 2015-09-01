# encoding: UTF-8

require 'spec_helper'

describe "Order By Clauses" do
  def with_select(statement)
    "SELECT * FROM phrases GROUP BY #{statement}"
  end

  def with_arel_select(statement)
    "Phrase.select(Arel.star).group(#{statement})"
  end

  it "works with a single column" do
    expect(convert(with_select("id"))).to eq(with_arel_select(":id"))
  end

  it "works with multiple columns" do
    expect(convert(with_select("id, key"))).to eq(with_arel_select(":id, :key"))
  end

  it "works with a function call" do
    expect(convert(with_select("STRLEN(key)"))).to eq(
      with_arel_select("Arel::Nodes::NamedFunction.new('STRLEN', [:key])")
    )
  end

  it "works with nested function calls where one is an aggregate" do
    expect(convert(with_select("STRLEN(COUNT(phrases.key))"))).to eq(
      with_arel_select("Arel::Nodes::NamedFunction.new('STRLEN', [Phrase.arel_table[:key].count])")
    )
  end

  it "works with nested function calls" do
    expect(convert(with_select("COALESCE(STRLEN(), 'abc')"))).to eq(
      with_arel_select("Arel::Nodes::NamedFunction.new('COALESCE', [Arel::Nodes::NamedFunction.new('STRLEN', []), 'abc'])")
    )
  end
end