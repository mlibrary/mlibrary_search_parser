# MlibrarySearchParser

A query parser that transforms user search strings into structured queries for both Solr and OpenSearch.

## Features

- Parses user search queries with Boolean operators (AND, OR, NOT)
- Supports field-specific searches (e.g., `title:hamlet author:shakespeare`)
- Handles phrase queries in double quotes
- Supports wildcards (`*`, `?`)
- Outputs to multiple formats:
  - **Solr**: JSON edismax format
  - **OpenSearch**: Query DSL format

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mlibrary_search_parser'
```

And then execute:

    $ bundle install

## Usage

### Basic Search

```ruby
require 'mlibrary_search_parser'

config = {
  query_fields: ['title', 'author', 'subject']
}

search = MLibrarySearchParser::Search.new("cats AND dogs", config)
```

### Output Formats

#### OpenSearch Query DSL

```ruby
config = {
  query_fields: ['title', 'author', 'subject'],
  output_format: :opensearch
}

search = MLibrarySearchParser::Search.new("cats AND dogs", config)
query = search.to_opensearch_query

# Returns:
# {
#   query: {
#     bool: {
#       must: [
#         { multi_match: { query: "cats", fields: ["title", "author", "subject"], type: "best_fields" } },
#         { multi_match: { query: "dogs", fields: ["title", "author", "subject"], type: "best_fields" } }
#       ]
#     }
#   }
# }
```

#### Solr JSON Edismax

```ruby
config = {
  query_fields: ['title', 'author', 'subject'],
  output_format: :solr
}

search = MLibrarySearchParser::Search.new("cats AND dogs", config)
solr_query = search.to_solr_query
```

### Query Examples

#### Simple Search
```ruby
# Input: "hamlet"
# OpenSearch: { query: { multi_match: { query: "hamlet", fields: [...] } } }
```

#### Boolean AND
```ruby
# Input: "cats AND dogs"
# OpenSearch: { query: { bool: { must: [<cats>, <dogs>] } } }
```

#### Boolean OR
```ruby
# Input: "cats OR dogs"
# OpenSearch: { query: { bool: { should: [<cats>, <dogs>], minimum_should_match: 1 } } }
```

#### Boolean NOT
```ruby
# Input: "cats NOT dogs"
# OpenSearch: { query: { bool: { must: [<cats>], must_not: [<dogs>] } } }
```

#### Phrase Query
```ruby
# Input: "\"complete works\""
# OpenSearch: { query: { match_phrase: { title: "complete works" } } }
```

#### Field-Specific Search
```ruby
# Input: "title:hamlet author:shakespeare"
# OpenSearch: { query: { bool: { must: [
#   { match: { title: "hamlet" } },
#   { match: { author: "shakespeare" } }
# ] } } }
```

#### Wildcard Query
```ruby
# Input: "prog*"
# OpenSearch: { query: { query_string: { query: "prog*", default_operator: "AND" } } }
```

#### Complex Nested Query
```ruby
# Input: "(cats OR dogs) AND NOT birds"
# OpenSearch: { query: { bool: {
#   must: [{ bool: { should: [<cats>, <dogs>], minimum_should_match: 1 } }],
#   must_not: [<birds>]
# } } }
```

## Configuration

### Required Configuration

- `query_fields`: Array of field names to search across (e.g., `['title', 'author', 'subject']`)

### Optional Configuration

- `output_format`: `:opensearch` or `:solr` (determines output format)

## OpenSearch Query DSL Mapping

The parser transforms AST nodes to OpenSearch queries as follows:

| Node Type    | OpenSearch Query Type                  | Description                                    |
|--------------|----------------------------------------|------------------------------------------------|
| TokensNode   | `match`, `match_phrase`, `multi_match` | Simple terms or phrases                        |
| AndNode      | `bool` with `must`                     | All clauses must match                         |
| OrNode       | `bool` with `should`                   | At least one clause must match                 |
| NotNode      | `bool` with `must_not`                 | Exclude matching documents                     |
| FieldedNode  | Field-specific queries                 | Search in specific field                       |
| SearchNode   | Top-level query wrapper                | Combines multiple clauses                      |
| Wildcard     | `query_string`                         | Wildcard patterns (`*`, `?`)                   |

## Limitations and Differences

### OpenSearch vs Solr Output

1. **Structure**: OpenSearch uses JSON Query DSL, Solr uses edismax parameters
2. **Field handling**: OpenSearch uses `multi_match` for cross-field searches
3. **Wildcards**: OpenSearch uses `query_string`, Solr uses edismax wildcard syntax
4. **Negation**: OpenSearch requires `bool` with `must_not`, Solr uses `-` prefix

### Known Limitations

- Range queries (`[1 TO 100]`) are not yet supported in OpenSearch output
- Fuzzy matching (`~`) uses `query_string` in OpenSearch, which may behave differently than Solr
- Field-specific phrase queries default to the first query field if no specific field mapping exists

## Development

### Running Tests

```bash
bundle exec rspec
```

### Test Coverage

The test suite includes:
- 166 tests for core parser functionality
- 32 tests for OpenSearch Query DSL output
- Coverage: 95.9% (1545/1611 LOC)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

