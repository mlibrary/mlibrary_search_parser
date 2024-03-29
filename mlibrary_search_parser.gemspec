require_relative "lib/mlibrary_search_parser/version"

Gem::Specification.new do |spec|
  spec.name = "mlibrary_search_parser"
  spec.version = MLibrarySearchParser::VERSION
  spec.authors = ["Bill Dueber"]
  spec.email = ["bill@dueber.com"]

  spec.summary = "Search parser for keyword, fielded, boolean queries"
  spec.homepage = "https://github.com/mlibrary/mlibrary_search_parser"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dotenv"
  spec.add_dependency "parslet"
  spec.add_dependency "erb"
  spec.add_development_dependency "rspec", "~>3.0"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "solr_wrapper"
  spec.add_development_dependency "simple_solr_client"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "standard"
end
