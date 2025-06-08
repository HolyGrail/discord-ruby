# Claude Code Rules for Discord Ruby Gem

This document outlines the development rules and guidelines for using Claude Code with the Discord Ruby gem project.

## Project Standards

### Dependency Management
- **Philosophy**: Use latest gem versions by default
- **Gemfile**: No version constraints unless necessary for compatibility
- **Gemspec**: Minimal runtime dependency constraints
- **Lock Policy**: Only pin versions when specific compatibility issues arise
- **Updates**: Regularly update dependencies to latest versions

### Ruby Version
- **Development**: Ruby 3.4.4 (see `.ruby-version`)
- **Support**: Ruby 3.3+ (minimum requirement)
- **Testing**: Ruby 3.3 and 3.4 in CI

### Code Style
- **Standard**: Use StandardRB for all Ruby code
- **Configuration**: See `.standard.yml`
- **Enforcement**: CI checks with StandardRB
- **Auto-fix**: Run `bundle exec standardrb --fix` before committing

## Documentation Requirements

### YARD Documentation
- **Required**: All public methods must have YARD documentation
- **Format**: Include `@param`, `@return`, `@raise`, and `@example` tags
- **Generation**: Run `bundle exec yard` to generate docs
- **Validation**: CI fails on YARD warnings

### Examples
- All public methods should include practical examples in YARD comments
- Keep examples simple and focused on the method's primary use case
- Use realistic Discord IDs and content in examples

### README Maintenance
- Update README.md when adding new features
- Include Getting Started examples for new functionality
- Keep feature list current

## Testing Standards

### RSpec Configuration
- **Framework**: RSpec 3.12+
- **Mocking**: Use WebMock for HTTP requests (no VCR)
- **Coverage**: Aim for comprehensive test coverage
- **Structure**: Follow `spec/discord/` directory structure

### Test Requirements
- Unit tests for all public methods
- Integration tests for complex workflows
- Error handling tests for API failures
- Thread-safety tests for concurrent operations

### Test Patterns
```ruby
# HTTP API tests should mock requests
stub_request(:get, "https://discord.com/api/v10/endpoint")
  .to_return(status: 200, body: '{"result": "data"}')

# Event tests should verify handler calls
expect(client.events).to receive(:on).with(:event_name, &handler)

# Error tests should check specific exception types
expect { subject }.to raise_error(Discord::APIError, "specific message")
```

## Code Organization

### Module Structure
```
lib/discord/
├── version.rb          # Version constant
├── client.rb           # Main client class
├── gateway.rb          # WebSocket connection
├── http.rb             # REST API client
└── events.rb           # Event handling system
```

### Error Handling
- Use custom exception classes (`Discord::APIError`, `Discord::AuthenticationError`)
- Include helpful error messages with context
- Handle rate limiting gracefully

### Threading
- Event handlers run in separate threads
- Use thread-safe data structures (Concurrent::Hash)
- Handle exceptions in threads to prevent crashes

## Development Workflow

### Before Committing
1. Run tests: `bundle exec rake spec`
2. Run linter: `bundle exec standardrb`
3. Generate docs: `bundle exec yard doc --fail-on-warning`
4. Update CHANGELOG.md if needed

### Commit Messages
- Use conventional commit format
- Include Claude Code attribution:
  ```
  🤖 Generated with [Claude Code](https://claude.ai/code)
  
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

### CI Requirements
- All tests must pass on Ruby 3.3 and 3.4
- StandardRB checks must pass
- YARD documentation must generate without warnings
- No new security vulnerabilities

## Implementation Guidelines

### Discord API Integration
- Use Discord API v10 endpoints
- Follow Discord's rate limiting guidelines
- Implement proper error handling for API responses
- Support both REST API and Gateway WebSocket

### Client Design Principles
- Event-driven architecture with clear handler registration
- Intuitive method names following Discord API conventions
- Comprehensive parameter validation
- Clear separation of concerns between modules

### Performance Considerations
- Use connection pooling for HTTP requests
- Implement efficient event dispatching
- Handle WebSocket reconnections gracefully
- Monitor memory usage in long-running bots

## Security Guidelines

### Token Management
- Never log or expose Discord bot tokens
- Use environment variables for sensitive data
- Validate token format before use
- Handle authentication errors gracefully

### Input Validation
- Sanitize user inputs before sending to Discord API
- Validate Discord IDs format and ranges
- Check message content length limits
- Prevent injection attacks in user data

## Maintenance Tasks

### Regular Updates
- Monitor Discord API changes and deprecations
- Update dependencies regularly
- Review and update documentation
- Test with latest Ruby versions

### Issue Tracking
- Use GitHub Issues for bug reports and feature requests
- Label issues appropriately (bug, enhancement, documentation)
- Provide reproduction steps for bugs
- Include Discord Ruby version and Ruby version in reports

## Claude Code Specific Guidelines

### When Making Changes
1. Always run existing tests first
2. Update tests when changing behavior
3. Add YARD documentation for new methods
4. Follow existing code patterns and style
5. Update CHANGELOG.md for notable changes

### Debugging Approach
1. Use `bundle exec rake spec` to run all tests
2. Use `bundle exec standardrb --fix` to fix style issues
3. Check `bundle exec yard doc` for documentation issues
4. Test manually with example bot when needed

### Code Review Checklist
- [ ] Tests added/updated for changes
- [ ] YARD documentation added for public methods
- [ ] StandardRB passes without warnings
- [ ] CHANGELOG.md updated if needed
- [ ] No sensitive information exposed
- [ ] Error handling implemented properly
- [ ] Thread safety considered if applicable