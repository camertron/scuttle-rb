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
    expect(convert(with_select("WHERE 1"))).to eq(with_arel_select("1"))
  end

  it "wraps literals that are the first operands in an expression" do
    expect(convert(with_select("WHERE 1 = 1"))).to eq(
      with_arel_select("Arel::Nodes::SqlLiteral.new('1').eq(1)")
    )
  end

  it "works with a column name on the left-hand side of an expression" do
    expect(convert(with_select("WHERE id = 1"))).to eq(
      with_arel_select("Phrase.arel_table[:id].eq(1)")
    )
  end

  it "works with a qualified column name on the left-hand side of an expression" do
    expect(convert(with_select("WHERE phrases.id = 1"))).to eq(
      with_arel_select("Phrase.arel_table[:id].eq(1)")
    )
  end

  it "works with a column name on the right-hand side of an expression" do
    expect(convert(with_select("WHERE 1 = phrases.id"))).to eq(
      with_arel_select("Arel::Nodes::SqlLiteral.new('1').eq(Phrase.arel_table[:id])")
    )
  end

  it "works with column names on both sides of an expression" do
    expect(convert(with_select("WHERE phrases.key = phrases.meta_key"))).to eq(
      with_arel_select("Phrase.arel_table[:key].eq(Phrase.arel_table[:meta_key])")
    )
  end

  it "works with inequality operators with two columns" do
    expect(convert(with_select("WHERE phrases.key > phrases.meta_key"))).to eq(
      with_arel_select("Phrase.arel_table[:key].gt(Phrase.arel_table[:meta_key])")
    )

    expect(convert(with_select("WHERE phrases.key < phrases.meta_key"))).to eq(
      with_arel_select("Phrase.arel_table[:key].lt(Phrase.arel_table[:meta_key])")
    )

    expect(convert(with_select("WHERE phrases.key >= phrases.meta_key"))).to eq(
      with_arel_select("Phrase.arel_table[:key].gteq(Phrase.arel_table[:meta_key])")
    )

    expect(convert(with_select("WHERE phrases.key <= phrases.meta_key"))).to eq(
      with_arel_select("Phrase.arel_table[:key].lteq(Phrase.arel_table[:meta_key])")
    )
  end

  it "works with inequality operators with columns and literals" do
    expect(convert(with_select("WHERE phrases.key > 1"))).to eq(
      with_arel_select("Phrase.arel_table[:key].gt(1)")
    )

    expect(convert(with_select("WHERE phrases.key < 2"))).to eq(
      with_arel_select("Phrase.arel_table[:key].lt(2)")
    )

    expect(convert(with_select("WHERE phrases.key >= 3"))).to eq(
      with_arel_select("Phrase.arel_table[:key].gteq(3)")
    )

    expect(convert(with_select("WHERE phrases.key <= 4"))).to eq(
      with_arel_select("Phrase.arel_table[:key].lteq(4)")
    )
  end

  it "works with NULL condition" do
    expect(convert(with_select("WHERE phrases.key IS NULL"))).to eq(
      with_arel_select("Phrase.arel_table[:key].eq(nil)")
    )
  end

  it "works with NOT NULL condition" do
    expect(convert(with_select("WHERE phrases.key IS NOT NULL"))).to eq(
      with_arel_select("Phrase.arel_table[:key].not_eq(nil)")
    )
  end

  it "works with a basic AND" do
    expect(convert(with_select("WHERE phrases.key = 'abc' AND phrases.id = 22"))).to eq(
      with_arel_select("Phrase.arel_table[:key].eq('abc').and(Phrase.arel_table[:id].eq(22))")
    )
  end

  it "works with a basic OR" do
    expect(convert(with_select("WHERE phrases.key = 'abc' OR phrases.id = 22"))).to eq(
      with_arel_select("Phrase.arel_table[:key].eq('abc').or(Phrase.arel_table[:id].eq(22))")
    )
  end

  it "works with chained ANDs and ORs" do
    expect(convert(with_select("WHERE phrases.key = 'abc' AND (phrases.id = 22 OR phrases.id = 109)"))).to eq(
      with_arel_select("Phrase.arel_table[:key].eq('abc').and(Phrase.arel_table[:id].eq(22).or(Phrase.arel_table[:id].eq(109)))")
    )
  end

  it "works with a single-element IN list" do
    expect(convert(with_select("WHERE phrases.id IN (1)"))).to eq(
      with_arel_select("Phrase.arel_table[:id].in(1)")
    )
  end

  it "works with a simple IN list" do
    expect(convert(with_select("WHERE phrases.id IN (1, 2, 3, 4)"))).to eq(
      with_arel_select("Phrase.arel_table[:id].in([1, 2, 3, 4])")
    )
  end

  it "works with an IN that contains a select statement (rails >= 6.0)" do
    expect(convert(with_select("WHERE phrases.id IN (SELECT id FROM phrases WHERE 1)"))).to eq(
      with_arel_select("Phrase.arel_table[:id].in(Phrase.select(:id).where(1))")
    )
  end

  it "works with an IN that contains a select statement (rails < 6.0)" do
    stmt = convert(with_select("WHERE phrases.id IN (SELECT id FROM phrases WHERE 1)"), use_rails_version: '5.2.1')
    expect(stmt).to eq(
      with_arel_select("Phrase.arel_table[:id].in(Phrase.select(:id).where(1).ast)")
    )
  end

  it "works with a basic between statement" do
    expect(convert(with_select("WHERE phrases.id BETWEEN 1 and 2"))).to eq(
      with_arel_select("Arel::Nodes::Between.new(Phrase.arel_table[:id], (Arel::Nodes::Group.new(1)).and(2))")
    )
  end

  it "works with a complex between statement" do
    expect(convert(with_select("WHERE phrases.id BETWEEN phrases.id + 1 AND phrases.id + 2"))).to eq(
      with_arel_select("Arel::Nodes::Between.new(Phrase.arel_table[:id], (Phrase.arel_table[:id] + 1).and(Phrase.arel_table[:id] + 2))")
    )
  end

  it "supports EXISTS subqueries" do
    expect(convert(with_select("WHERE EXISTS (SELECT * FROM phrases WHERE id = 1)"))).to eq(
      "Phrase.select(Arel.star).where(Phrase.select(Arel.star).where(Phrase.arel_table[:id].eq(1)).exists)"
    )
  end

  it "supports HAVING clauses" do
    expect(convert(with_select("HAVING COUNT(*) > 5"))).to eq(
      "Phrase.select(Arel.star).having(Arel.star.count.gt(5))"
    )
  end

  it "supports boolean IS expressions" do
    expect(convert(with_select("WHERE phrases.active IS TRUE"))).to eq(
      "Phrase.select(Arel.star).where(Phrase.arel_table[:active].eq(true))"
    )
  end
end
