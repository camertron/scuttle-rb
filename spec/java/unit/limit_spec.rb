# encoding: UTF-8

require 'spec_helper'

describe "Order By Clauses" do
  def with_limit(statement)
    "SELECT * FROM phrases LIMIT #{statement}"
  end

  def with_arel_limit(statement)
    "Phrase.select(Arel.star)#{statement}"
  end

  it "works with a common numerical select" do
    convert(with_limit("1")).should ==
      with_arel_limit(".limit(1)")
  end

  it "works with an expression" do
    convert(with_limit("COUNT(phrases.id)")).should ==
      with_arel_limit(".limit(Phrase.arel_table[:id].count)")
  end
end