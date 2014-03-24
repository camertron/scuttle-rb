# encoding: UTF-8

require 'spec_helper'

describe "Join Clauses" do
  def with_select(statement)
    "SELECT * FROM phrases #{statement}"
  end

  def with_arel_select(statement)
    "Phrase.select(Arel.star).joins(#{statement})"
  end

  it "works for the simplest kind join" do
    convert(with_select("JOIN translations ON translations.phrase_id = phrases.id")).should ==
      with_arel_select("Phrase.arel_table.join(Translation.arel_table).on(Translation.arel_table[:phrase_id].eq(Phrase.arel_table[:id])).join_sources")
  end

  it "works for joins with multiple conditions" do
    convert(with_select("JOIN translations ON translations.phrase_id = phrases.id AND translations.meta_key = 'abc'")).should ==
      with_arel_select("Phrase.arel_table.join(Translation.arel_table).on(Translation.arel_table[:phrase_id].eq(Phrase.arel_table[:id]).and(Translation.arel_table[:meta_key].eq('abc'))).join_sources")
  end

  it "allows outer joins" do
    convert(with_select("LEFT OUTER JOIN translations ON translations.phrase_id = phrases.id")).should ==
      with_arel_select("Phrase.arel_table.join(Translation.arel_table, Arel::Nodes::OuterJoin).on(Translation.arel_table[:phrase_id].eq(Phrase.arel_table[:id])).join_sources")
  end
end