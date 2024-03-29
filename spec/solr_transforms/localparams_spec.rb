require_relative "../spec_helper"
require "mlibrary_search_parser/transform/solr/local_params"

# Build up a localparams object based on the given search string

def localparams(str)
  search = catalog_search(str)
  MLibrarySearchParser::Transformer::Solr::LocalParams.new(search)
end

RSpec.describe MLibrarySearchParser::Transformer::Solr::LocalParams do
  describe "handles OR" do
    it "with field" do
      lp = localparams("one OR title:two")
      expect(lp.clean_string).to eq("(one OR title:two)")
    end

    it "without field" do
      lp = localparams("one OR two")
      expect(lp.clean_string).to eq("(one OR two)")
    end
  end

  describe "Special cases" do
    it "Correctly handles a lone NOT clause" do
      lp = localparams("NOT one")
      expect(lp.query).to match(/AND NOT/)
    end
  end

  describe "Correctly use mm with/without booleans" do
    it "adds mm for non-boolean search" do
      lp = localparams("one two")
      expect(lp.query).to match(/mm=\$default_mm/)
    end

    it "doesn't add mm for boolean search" do
      lp = localparams("one AND two")
      expect(lp.query).to_not match(/mm=\$default_mm/)
    end
  end

  describe "correctly deals with asterisks for wildcard search" do
    it "doesn't escape the end of a word" do
      lp = localparams("wildcard*")
      expect(lp.params[:q1]).to eq("wildcard*")
    end

    it "doesn't escape with multiple words" do
      lp = localparams("one wildcard* two")
      expect(lp.params[:q1]).to eq("(one wildcard* two)")
    end

    it "does escape in the middle of a word" do
      lp = localparams("title:one two*three four*")
      expect(lp.params[:q2]).to eq('(one two\\*three four*)')
    end

    it "handles the single-asterisk search" do
      lp = localparams("*")
      expect(lp.params[:q]).to eq("*:*")
    end
  end

  describe "shakes" do
    it "combines matching fieldeds into one" do
      lp = localparams("title:one AND title:two")
      expect(lp.params[:clean_string]).to eq("title:(one AND two)")
    end

    it "shakes a NOT" do
      lp = localparams("subject:one NOT subject:two")
      expect(lp.params[:clean_string]).to eq("subject:one (NOT (subject:(two)))")
    end

    it "shakes an AND" do
      lp = localparams("one AND two")
      expect(lp.params[:clean_string]).to eq("(one AND two)")
    end

    it "shakes out an empty node inside a field" do
      lp = localparams("one title:()")
      expect(lp.params[:clean_string]).to eq("one")
    end
  end
end
