# frozen_string_literal: true

require_relative "lib/discord/version"

Gem::Specification.new do |spec|
  spec.name = "discord-ruby"
  spec.version = Discord::VERSION
  spec.authors = ["HolyGrail"]
  spec.email = ["holygrail81@gmail.com"]

  spec.summary = "A Ruby client library for Discord API"
  spec.description = "A comprehensive Ruby gem for interacting with Discord's REST API and Gateway WebSocket"
  spec.homepage = "https://github.com/HolyGrail/discord-ruby"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "websocket-client-simple", "~> 0.8"
  spec.add_dependency "rest-client", "~> 2.1"
  spec.add_dependency "json", "~> 2.6"
  spec.add_dependency "concurrent-ruby", "~> 1.2"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
end
