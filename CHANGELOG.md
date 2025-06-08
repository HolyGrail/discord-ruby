# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Updated minimum Ruby version requirement to 3.3
- Added support for Ruby 3.4
- Adopted StandardRB for code style enforcement

## [0.1.0] - 2024-01-06

### Added
- Initial release of discord-ruby gem
- Discord API v10 support
- WebSocket Gateway connection with automatic reconnection
- REST API client with rate limiting support
- Thread-safe event handling system
- Basic bot functionality:
  - Message sending, editing, and deletion
  - Reaction management
  - Channel, guild, and user information retrieval
  - Presence updates
- Comprehensive documentation with YARD
- RSpec test suite
- Example bot implementation

[Unreleased]: https://github.com/HolyGrail/discord-ruby/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/HolyGrail/discord-ruby/releases/tag/v0.1.0