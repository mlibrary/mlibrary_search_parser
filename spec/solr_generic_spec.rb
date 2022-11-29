# frozen_string_literal: true

require "spec_helper"
require "mlibrary_search_parser/transform/solr/utilities"

RSpec.describe "Generic Solr stuff" do
  describe "escaping" do
    class Escaper
      extend MLibrarySearchParser::Transformer::Solr::Utilities
    end

    # Ruby also uses '\' as an escape character, so we check for
    # '\\' instead of '\\\\'
    def e(str)
      Escaper.lucene_escape(str)
    end

    it "one two" do
      expect(e("one two")).to eq("one two")
    end

    it "one ^ two" do
      expect(e("one ^ two")).to eq("one \\^ two")
    end

    it "one two!" do
      expect(e("one two!")).to eq("one two\\!")
    end

    it "one +two" do
      expect(e("one +two")).to eq("one +two")
    end

    it "one + two" do
      expect(e("one + two")).to eq('one \\+ two')
    end

    it "one+" do
      expect(e("one+")).to eq('one\\+')
    end
  end
end
