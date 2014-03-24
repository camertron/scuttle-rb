# encoding: UTF-8

require 'spec_helper'

describe "Select Statements" do
  it "works with a star" do
    convert("SELECT * FROM phrases").should == "Phrase.select(Arel.star)"
  end

  it "works with a single column" do
    convert("SELECT phrases.key FROM phrases").should == "Phrase.select(Phrase.arel_table[:key])"
  end

  it "works with a single non-qualified column" do
    convert("SELECT id from phrases").should == "Phrase.select(:id)"
  end

  it "works with multiple qualified and non-qualified columns" do
    convert("SELECT id, phrases.meta_key, key from phrases").should ==
      "Phrase.select(:id, Phrase.arel_table[:meta_key], :key)"
  end

  it "works with multiple columns" do
    convert("SELECT phrases.key, translations.text FROM phrases").should ==
      "Phrase.select(Phrase.arel_table[:key], Translation.arel_table[:text])"
  end

  it "works with a wildcard instead of a column name" do
    convert("SELECT phrases.* FROM phrases").should == "Phrase.select(Phrase.arel_table[Arel.star])"
  end

  it "works when counting over a star (other aggregate functions don't allow stars)" do
    convert("SELECT COUNT(*) FROM phrases").should == "Phrase.select(Arel.star.count)"
  end

  it "works with aggregate functions" do
    convert("SELECT COUNT(phrases.created_at) FROM phrases").should ==
      "Phrase.select(Phrase.arel_table[:created_at].count)"
    convert("SELECT MAX(phrases.created_at) FROM phrases").should ==
      "Phrase.select(Phrase.arel_table[:created_at].maximum)"
    convert("SELECT AVG(phrases.created_at) FROM phrases").should ==
      "Phrase.select(Phrase.arel_table[:created_at].average)"
  end

  it "works with nested aggregate functions" do
    convert("SELECT COUNT(MAX(phrases.key)) FROM phrases").should ==
      "Phrase.select(Phrase.arel_table[:key].maximum.count)"
  end

  it "works with function calls" do
    convert("SELECT STRLEN(phrase.key) FROM phrases").should ==
      "Phrase.select(Arel::Nodes::NamedFunction.new('STRLEN', [Phrase.arel_table[:key]]))"
  end

  it "allows function calls to accept literals as well as columns" do
    convert("SELECT COALESCE(phrases.key, 1, 'abc') FROM phrases").should ==
      "Phrase.select(Arel::Nodes::NamedFunction.new('COALESCE', [Phrase.arel_table[:key], 1, 'abc']))"
  end

  it "allows arithmetic with integer literals" do
    convert("SELECT phrases.counter + 1 FROM phrases").should ==
      "Phrase.select(Phrase.arel_table[:counter] + 1)"
  end

  it "allows arithmetic with columns" do
    convert("SELECT phrases.counter + phrases.key FROM phrases").should ==
      "Phrase.select(Phrase.arel_table[:counter] + Phrase.arel_table[:key])"
  end

  it "allows parenthesized arithmetic via arel groups" do
    convert("SELECT phrases.key + (phrases.counter / 5) FROM phrases").should ==
      "Phrase.select(Phrase.arel_table[:key] + Arel::Nodes::Group.new(Phrase.arel_table[:counter] / 5))"
  end

  it "works with column aliases" do
    convert("SELECT phrases.key AS key FROM phrases").should ==
      "Phrase.select(Phrase.arel_table[:key].as('key'))"
  end

  it "works with a crazy example that ties all this together" do
    convert("SELECT COALESCE(1, 'a', (phrases.key + 1)) AS `col`, COUNT(*), STRLEN(phrases.key), phrases.created_at FROM phrases").should ==
      "Phrase.select(Arel::Nodes::NamedFunction.new('COALESCE', [1, 'a', Arel::Nodes::Group.new(Phrase.arel_table[:key] + 1)]).as('col'), Arel.star.count, Arel::Nodes::NamedFunction.new('STRLEN', [Phrase.arel_table[:key]]), Phrase.arel_table[:created_at])"
  end
end
