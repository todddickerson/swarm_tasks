# frozen_string_literal: true

require_relative "lib/swarm_tasks/version"

Gem::Specification.new do |spec|
  spec.name = "swarm_tasks"
  spec.version = SwarmTasks::VERSION
  spec.authors = ["Claude Swarm Community"]
  spec.email = ["swarm@anthropic.com"]

  spec.summary = "Task management system for Claude Swarm and autonomous agents"
  spec.description = "A simple, directory-based task management system designed for AI agents and human developers. Perfect for Claude Swarm projects."
  spec.homepage = "https://github.com/anthropics/swarm_tasks"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "front_matter_parser", "~> 1.0"
  spec.add_dependency "tty-table", "~> 0.12"
  spec.add_dependency "pastel", "~> 0.8"
  
  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "simplecov", "~> 0.22"
end