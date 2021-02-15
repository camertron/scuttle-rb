# encoding: UTF-8

require 'spec_helper'

describe "Select Statements" do
  it "works with a star" do
    expect(convert("SELECT * FROM phrases")).to eq("Phrase.select(Arel.star)")
  end

  it "works with a single column" do
    expect(convert("SELECT phrases.key FROM phrases")).to eq("Phrase.select(Phrase.arel_table[:key])")
  end

  it "works with a single non-qualified column" do
    expect(convert("SELECT id from phrases")).to eq("Phrase.select(:id)")
  end

  it "works with multiple qualified and non-qualified columns" do
    expect(convert("SELECT id, phrases.meta_key, key from phrases")).to eq(
      "Phrase.select([:id, Phrase.arel_table[:meta_key], :key])"
    )
  end

  it "works with multiple columns" do
    expect(convert("SELECT phrases.key, translations.text FROM phrases")).to eq(
      "Phrase.select([Phrase.arel_table[:key], Translation.arel_table[:text]])"
    )
  end

  it "works with a wildcard instead of a column name" do
    expect(convert("SELECT phrases.* FROM phrases")).to eq("Phrase.select(Phrase.arel_table[Arel.star])")
  end

  it "works when counting over a star (other aggregate functions don't allow stars)" do
    expect(convert("SELECT COUNT(*) FROM phrases")).to eq("Phrase.select(Arel.star.count)")
  end

  it "works with aggregate functions" do
    expect(convert("SELECT COUNT(phrases.created_at) FROM phrases")).to eq(
      "Phrase.select(Phrase.arel_table[:created_at].count)"
    )
    expect(convert("SELECT MAX(phrases.created_at) FROM phrases")).to eq(
      "Phrase.select(Phrase.arel_table[:created_at].maximum)"
    )
    expect(convert("SELECT AVG(phrases.created_at) FROM phrases")).to eq(
      "Phrase.select(Phrase.arel_table[:created_at].average)"
    )
  end

  it "works with nested aggregate functions" do
    expect(convert("SELECT COUNT(MAX(phrases.key)) FROM phrases")).to eq(
      "Phrase.select(Phrase.arel_table[:key].maximum.count)"
    )
  end

  it "works with function calls" do
    expect(convert("SELECT STRLEN(phrase.key) FROM phrases")).to eq(
      "Phrase.select(Arel::Nodes::NamedFunction.new('STRLEN', [Phrase.arel_table[:key]]))"
    )
  end

  it "allows function calls to accept literals as well as columns" do
    expect(convert("SELECT COALESCE(phrases.key, 1, 'abc') FROM phrases")).to eq(
      "Phrase.select(Arel::Nodes::NamedFunction.new('COALESCE', [Phrase.arel_table[:key], 1, 'abc']))"
    )
  end

  it "allows arithmetic with integer literals" do
    expect(convert("SELECT phrases.counter + 1 FROM phrases")).to eq(
      "Phrase.select(Phrase.arel_table[:counter] + 1)"
    )
  end

  it "allows arithmetic with columns" do
    expect(convert("SELECT phrases.counter + phrases.key FROM phrases")).to eq(
      "Phrase.select(Phrase.arel_table[:counter] + Phrase.arel_table[:key])"
    )
  end

  it "allows parenthesized arithmetic via arel groups" do
    expect(convert("SELECT phrases.key + (phrases.counter / 5) FROM phrases")).to eq(
      "Phrase.select(Phrase.arel_table[:key] + Arel::Nodes::Group.new(Phrase.arel_table[:counter] / 5))"
    )
  end

  it "works with column aliases" do
    expect(convert("SELECT phrases.key AS key FROM phrases")).to eq(
      "Phrase.select(Phrase.arel_table[:key].as('key'))"
    )
  end

  it "works with a crazy example that ties all this together" do
    expect(convert("SELECT COALESCE(1, 'a', (phrases.key + 1)) AS `col`, COUNT(*), STRLEN(phrases.key), phrases.created_at FROM phrases")).to eq(
      "Phrase.select([Arel::Nodes::NamedFunction.new('COALESCE', [1, 'a', Arel::Nodes::Group.new(Phrase.arel_table[:key] + 1)]).as('col'), Arel.star.count, Arel::Nodes::NamedFunction.new('STRLEN', [Phrase.arel_table[:key]]), Phrase.arel_table[:created_at]])"
    )
  end

  it "allows FROM clauses to contain subqueries" do
    expect(convert("SELECT ph.* FROM (SELECT COUNT(phrases.id) FROM phrases) ph")).to eq(
      "ph = Arel::Table.new('ph')\nPhrase.select(ph[Arel.star]).from(Phrase.select(Phrase.arel_table[:id].count).as('ph'))"
    )
  end

  it "works with DISTINCT queries" do
    expect(convert("SELECT DISTINCT id FROM phrases")).to eq(
      "Phrase.select(:id).uniq"
    )
  end

  it "doesn't use the Arel::Nodes namespace when option is given" do
    expect(convert("SELECT COALESCE(phrases.key, 1, 'abc') FROM phrases", use_arel_nodes_prefix: false)).to eq(
      "Phrase.select(NamedFunction.new('COALESCE', [Phrase.arel_table[:key], 1, 'abc']))"
    )
  end

  it "uses ArelHelpers when option is given" do
    expect(convert("SELECT phrases.key FROM phrases", use_arel_helpers: true)).to eq(
      "Phrase.select(Phrase[:key])"
    )
  end

  it "handles simple SQL CASE statements (rails < 5)" do
    result = convert("SELECT SUM(CASE phrases.id WHEN 10 THEN 1 ELSE 0 END) whatever FROM phrases", use_rails_version: '4.2.0')
    expect(result).to eq("Phrase.select(Arel::Nodes::NamedFunction.new('SUM', [Arel.sql('CASE phrases.id WHEN 10 THEN 1 ELSE 0 END')]).as('whatever'))")
  end

  it "handles searched SQL CASE statements (rails < 5)" do
    result = convert("SELECT SUM(CASE WHEN phrases.translated THEN 1 ELSE 0 END) total_translated FROM phrases", use_rails_version: '4.2.0')
    expect(result).to eq("Phrase.select(Arel::Nodes::NamedFunction.new('SUM', [Arel.sql('CASE WHEN phrases.translated THEN 1 ELSE 0 END')]).as('total_translated'))")
  end

  it "handles searched SQL CASE statements (rails >= 5)" do
    result = convert("SELECT SUM(CASE phrases.id WHEN 10 THEN 1 ELSE 0 END) total_translated FROM phrases", use_rails_version: '5.0.0')
    expect(result).to eq("Phrase.select(Arel::Nodes::NamedFunction.new('SUM', [Arel::Nodes::Case.new(Phrase.arel_table[:id]).when(10).then(1).else(0)]).as('total_translated'))")
  end

  it "handles searched SQL CASE statements (rails >= 5)" do
    result = convert("SELECT SUM(CASE WHEN phrases.translated THEN 1 ELSE 0 END) total_translated FROM phrases", use_rails_version: '5.0.0')
    expect(result).to eq("Phrase.select(Arel::Nodes::NamedFunction.new('SUM', [Arel::Nodes::Case.new.when(Phrase.arel_table[:translated]).then(1).else(0)]).as('total_translated'))")
  end

  context "window functions (OVER)" do
    it "works with ROW_NUMBER()" do
      result = convert("SELECT row_number() OVER () AS id, COUNT(*) as count FROM translations GROUP BY translations.phrase_id")
      expect(result).to eq("Translation.select([Arel::Nodes::NamedFunction.new('ROW_NUMBER', []).over.as('id'), Arel.star.count.as('count')]).group(Translation.arel_table[:phrase_id])")
    end

    it "works with other aggregate functions" do
      result = convert("SELECT avg(foo) OVER () as bar FROM translations")
      expect(result).to eq("Translation.select(Translation.arel_table[:foo].average.over.as('bar'))")

      result = convert("SELECT sum(translations.foo) OVER () as bar FROM translations")
      expect(result).to eq("Translation.select(Arel::Nodes::NamedFunction.new('SUM', [Translation.arel_table[:foo]]).over.as('bar'))")
    end
  end
end
