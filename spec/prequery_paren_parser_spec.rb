# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe "PreQueryParenthesisParser" do
  before do
    @parser = MLibrarySearchParser::PreQueryParenthesisParser.new
  end

  it "validates balanced parentheses" do
    expect { @parser.parse("(test)") }.not_to raise_error
  end

  it "validates sequential balanced parentheses" do
    expect { @parser.parse("(test)()") }.not_to raise_error
  end

  it "validates nested balanced parentheses" do
    expect { @parser.parse("( test ( thing )) ()") }.not_to raise_error
  end

  it "chokes on unbalanced left parenthesis" do
    expect { @parser.parse("(test") }.to raise_error(Parslet::ParseFailed)
  end

  it "chokes on unbalanced right parenthesis" do
    expect { @parser.parse("test)") }.to raise_error(Parslet::ParseFailed)
  end

  it "chokes on unbalanced sequential parenthesis" do
    expect { @parser.parse("(test)(") }.to raise_error(Parslet::ParseFailed)
  end

  it "chokes on unbalanced nested parenthesis" do
    expect { @parser.parse("(test (thing ())(") }.to raise_error(Parslet::ParseFailed)
  end

  it "chokes on out-of-order parentheses" do
    expect { @parser.parse(")test(") }.to raise_error(Parslet::ParseFailed)
  end

  it "allows paren embedded in a phrase" do
    expect { @parser.parse('( one two "three )" four)') }.not_to raise_error
  end
end
