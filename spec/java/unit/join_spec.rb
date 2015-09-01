# encoding: UTF-8

require 'spec_helper'

describe "Join Clauses" do
  def with_select(statement)
    "SELECT * FROM posts #{statement}"
  end

  def with_arel_select(statement)
    "Post.select(Arel.star).joins(#{statement})"
  end

  it "works for the simplest kind join" do
    expect(convert(with_select("JOIN comments ON comments.post_id = posts.id"))).to eq(
      with_arel_select("Post.arel_table.join(Comment.arel_table).on(Comment.arel_table[:post_id].eq(Post.arel_table[:id])).join_sources")
    )
  end

  it "works for joins with multiple conditions" do
    expect(convert(with_select("JOIN comments ON comments.post_id = posts.id AND comments.body = 'abc'"))).to eq(
      with_arel_select("Post.arel_table.join(Comment.arel_table).on(Comment.arel_table[:post_id].eq(Post.arel_table[:id]).and(Comment.arel_table[:body].eq('abc'))).join_sources")
    )
  end

  it "allows outer joins" do
    expect(convert(with_select("LEFT OUTER JOIN comments ON comments.post_id = posts.id"))).to eq(
      with_arel_select("Post.arel_table.join(Comment.arel_table, Arel::Nodes::OuterJoin).on(Comment.arel_table[:post_id].eq(Post.arel_table[:id])).join_sources")
    )
  end

  context "with associations defined" do
    let(:manager) do
      AssociationManager.new.tap do |manager|
        manager.addAssociation("posts", "comments", AssociationType::HAS_MANY)
        manager.addAssociation("posts", "favorites", AssociationType::HAS_MANY)
        manager.addAssociation("comments", "posts", AssociationType::BELONGS_TO)
        manager.addAssociation("comments", "authors", AssociationType::BELONGS_TO)
        manager.addAssociation("authors", "comments", AssociationType::HAS_ONE)
        manager.addAssociation("favorites", "posts", AssociationType::BELONGS_TO)
        manager.addAssociation("collab_posts", "authors", AssociationType::HAS_AND_BELONGS_TO_MANY)
        manager.addAssociation("authors", "collab_posts", AssociationType::HAS_AND_BELONGS_TO_MANY)
      end
    end

    it "identifies non-nested ActiveRecord associations" do
      expect(convert(with_select("INNER JOIN comments ON comments.post_id = posts.id"), {}, manager)).to eq(
        with_arel_select(":comments")
      )
    end

    it "identifies one level of association nesting" do
      expect(convert(
        with_select(
          "INNER JOIN comments ON comments.post_id = posts.id " +
          "INNER JOIN authors ON authors.id = comments.author_id"
        ), {}, manager
      )).to eq(with_arel_select(":comments => :author"))
    end

    # fix this
    it "identifies deeply nested ActiveRecord associations" do
      query = "SELECT * FROM authors " +
        "INNER JOIN comments ON comments.author_id = authors.id " +
        "INNER JOIN posts ON posts.id = comments.post_id " +
        "INNER JOIN favorites ON favorites.post_id = posts.id"

      expect(convert(query, {}, manager)).to eq(
        "Author.select(Arel.star).joins(:comment => { :post => :favorites })"
      )
    end

    it "works with has_and_belongs_to_many associations" do
      query = "SELECT authors.* FROM authors " +
        "INNER JOIN authors_collab_posts ON authors_collab_posts.author_id = authors.id " +
        "INNER JOIN collab_posts ON collab_posts.id = authors_collab_posts.collab_post_id"

      expect(convert(query, {}, manager)).to eq(
        "Author.select(Author.arel_table[Arel.star]).joins(:collab_posts)"
      )
    end

    it "works with has_and_belongs_to_many associations in the opposite direction" do
      query = "SELECT collab_posts.* FROM collab_posts " +
        "INNER JOIN authors_collab_posts ON authors_collab_posts.collab_post_id = collab_posts.id " +
        "INNER JOIN authors ON authors.id = authors_collab_posts.author_id"

      expect(convert(query, {}, manager)).to eq(
        "CollabPost.select(CollabPost.arel_table[Arel.star]).joins(:authors)"
      )
    end

    it "falls back to arel upon encountering an unsupported join type" do
      expect(convert(with_select("LEFT OUTER JOIN comments ON comments.post_id = posts.id"), {}, manager)).to eq(
        with_arel_select("Post.arel_table.join(Comment.arel_table, Arel::Nodes::OuterJoin).on(Comment.arel_table[:post_id].eq(Post.arel_table[:id])).join_sources")
      )
    end

    it "falls back to arel if the association can't be recognized" do
      expect(convert(with_select("INNER JOIN comments ON comments.body = posts.id"), {}, manager)).to eq(
        with_arel_select("Post.arel_table.join(Comment.arel_table).on(Comment.arel_table[:body].eq(Post.arel_table[:id])).join_sources")
      )
    end
  end

  context "with an association that defines a custom foreign key" do
    let(:manager) do
      AssociationManager.new.tap do |manager|
        manager.addAssociation("posts", "comments", AssociationType::HAS_MANY, nil, "my_post_id")
        manager.addAssociation("comments", "posts", AssociationType::BELONGS_TO, nil, "my_post_id")
      end
    end

    it "identifies joins that use a custom foreign key" do
      expect(convert(with_select("INNER JOIN comments ON posts.id = comments.my_post_id"), {}, manager)).to eq(
        with_arel_select(":comments")
      )

      expect(convert("SELECT * FROM comments INNER JOIN posts ON comments.my_post_id = posts.id", {}, manager)).to eq(
        "Comment.select(Arel.star).joins(:post)"
      )
    end
  end

  context "with an association that defines a custom association name" do
    let(:manager) do
      AssociationManager.new.tap do |manager|
        manager.addAssociation("posts", "comments", AssociationType::HAS_MANY, "utterances")
        manager.addAssociation("comments", "posts", AssociationType::BELONGS_TO)
      end
    end

    it "uses the custom association name instead of the table name in the join" do
      expect(convert(with_select("INNER JOIN comments ON posts.id = comments.post_id"), {}, manager)).to eq(
        with_arel_select(":utterances")
      )
    end
  end
end
