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
  spec.required_ruby_version = ">= 3.3.0"

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

  # Runtime dependencies - minimal version constraints for compatibility
  spec.add_dependency "websocket-client-simple"
  spec.add_dependency "rest-client"
  spec.add_dependency "json"
  spec.add_dependency "concurrent-ruby"
end
