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
    convert(with_select("JOIN comments ON comments.post_id = posts.id")).should ==
      with_arel_select("Post.arel_table.join(Comment.arel_table).on(Comment.arel_table[:post_id].eq(Post.arel_table[:id])).join_sources")
  end

  it "works for joins with multiple conditions" do
    convert(with_select("JOIN comments ON comments.post_id = posts.id AND comments.body = 'abc'")).should ==
      with_arel_select("Post.arel_table.join(Comment.arel_table).on(Comment.arel_table[:post_id].eq(Post.arel_table[:id]).and(Comment.arel_table[:body].eq('abc'))).join_sources")
  end

  it "allows outer joins" do
    convert(with_select("LEFT OUTER JOIN comments ON comments.post_id = posts.id")).should ==
      with_arel_select("Post.arel_table.join(Comment.arel_table, Arel::Nodes::OuterJoin).on(Comment.arel_table[:post_id].eq(Post.arel_table[:id])).join_sources")
  end

  context "with associations defined" do
    let(:manager) do
      manager = AssociationManager.new
      manager.addAssociation("posts", "comments", AssociationType::HAS_MANY)
      manager.addAssociation("posts", "favorites", AssociationType::HAS_MANY)
      manager.addAssociation("comments", "posts", AssociationType::BELONGS_TO)
      manager.addAssociation("comments", "authors", AssociationType::BELONGS_TO)
      manager.addAssociation("authors", "comments", AssociationType::HAS_ONE)
      manager.addAssociation("favorites", "posts", AssociationType::BELONGS_TO)
      # manager.addAssociation("collab_posts", "authors", AssociationType::HAS_AND_BELONGS_TO_MANY)
      manager
    end

    it "identifies non-nested ActiveRecord associations" do
      convert(with_select("INNER JOIN comments ON comments.post_id = posts.id"), manager).should ==
        with_arel_select(":comments")
    end

    it "identifies one level of association nesting" do
      convert(
        with_select(
          "INNER JOIN comments ON comments.post_id = posts.id " +
          "INNER JOIN authors ON authors.id = comments.author_id"
        ), manager
      ).should == with_arel_select(":comments => :author")
    end

    # fix this
    it "identifies deeply nested ActiveRecord associations" do
      query = "SELECT * FROM authors " +
        "INNER JOIN comments ON comments.author_id = authors.id " +
        "INNER JOIN posts ON posts.id = comments.post_id " +
        "INNER JOIN favorites ON favorites.post_id = posts.id"

      convert(query, manager).should ==
        "Author.select(Arel.star).joins(:comment => { :post => :favorites })"
    end

    it "works with has_and_belongs_to_many associations" do
      pending
      # convert()
    end

    it "falls back to arel upon encountering an unsupported join type" do
      convert(with_select("LEFT OUTER JOIN comments ON comments.post_id = posts.id"), manager).should ==
        with_arel_select("Post.arel_table.join(Comment.arel_table, Arel::Nodes::OuterJoin).on(Comment.arel_table[:post_id].eq(Post.arel_table[:id])).join_sources")
    end

    it "falls back to arel if the association can't be recognized" do
      convert(with_select("INNER JOIN comments ON comments.body = posts.id"), manager).should ==
        with_arel_select("Post.arel_table.join(Comment.arel_table).on(Comment.arel_table[:body].eq(Post.arel_table[:id])).join_sources")
    end
  end
end
