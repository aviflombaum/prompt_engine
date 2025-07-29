require_relative "lib/prompt_engine/version"

Gem::Specification.new do |spec|
  spec.name = "prompt_engine"
  spec.version = PromptEngine::VERSION
  spec.authors = [ "Avi Flombaum" ]
  spec.email = [ "4515+aviflombaum@users.noreply.github.com" ]
  spec.homepage = "https://github.com/aviflombaum/prompt_engine"
  spec.summary = "Rails mountable engine for AI prompt management"
  spec.description = "PromptEngine is a Rails mountable engine that provides a simple interface for managing AI prompts, templates, and responses within Rails applications."
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aviflombaum/prompt_engine"
  spec.metadata["changelog_uri"] = "https://github.com/aviflombaum/prompt_engine/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails"
  spec.add_dependency "ruby_llm"
  spec.add_dependency "bcrypt"
  spec.add_dependency "sqlite3"
  spec.add_dependency "csv", "~> 3.3"

  spec.add_development_dependency "rspec-rails", "~> 8.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.4"
  spec.add_development_dependency "vcr", "~> 6.3"
  spec.add_development_dependency "webmock", "~> 3.23"
  spec.add_development_dependency "capybara", "~> 3.40"
  spec.add_development_dependency "cuprite", "~> 0.15"
  spec.add_development_dependency "selenium-webdriver", "~> 4.27"
  spec.add_development_dependency "simplecov"
end
