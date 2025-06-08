# Contributing to Discord Ruby

Thank you for your interest in contributing to the Discord Ruby gem! This document provides guidelines and information about contributing to this project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## Getting Started

### Prerequisites

- Ruby 3.3 or higher (we develop with Ruby 3.4.4)
- Git
- A Discord bot token for testing (optional)

### Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/discord-ruby.git
   cd discord-ruby
   ```

2. **Run the setup script**
   ```bash
   bin/setup
   ```

3. **Verify everything works**
   ```bash
   bundle exec rake  # Runs tests and linting
   ```

### Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code following our standards (see below)
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   bundle exec rake spec      # Run tests
   bundle exec standardrb     # Check code style
   bundle exec yard doc       # Generate docs
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: description of your changes"
   ```

5. **Push and create a Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Development Standards

### Code Style

- **Ruby Style**: We use [StandardRB](https://github.com/testdouble/standard) for code formatting
- **Auto-fix**: Run `bundle exec standardrb --fix` to automatically fix style issues
- **Required**: All code must pass StandardRB checks

### Testing

- **Framework**: RSpec for all tests
- **Coverage**: Aim for high test coverage (we use SimpleCov)
- **Mocking**: Use WebMock for HTTP requests, no VCR
- **Required**: All new features must have tests

### Documentation

- **YARD**: All public methods must have YARD documentation
- **Examples**: Include `@example` tags showing realistic usage
- **Types**: Document parameters with `@param` and return values with `@return`
- **Required**: Documentation is validated in CI

### Git Workflow

- **Commits**: Write clear, descriptive commit messages
- **Branches**: Use descriptive branch names (`feature/slash-commands`, `fix/gateway-reconnect`)
- **History**: Keep commit history clean (squash if needed)

## Types of Contributions

### Bug Reports

When reporting bugs, please include:

- Ruby version
- Gem version
- Clear reproduction steps
- Expected vs actual behavior
- Error messages (if any)

### Feature Requests

For new features:

- Describe the use case
- Explain why it would be valuable
- Consider Discord API compatibility
- Be willing to help implement if accepted

### Code Contributions

We welcome contributions for:

- **Bug fixes**: Always appreciated
- **Discord API features**: Slash commands, interactions, file uploads, etc.
- **Performance improvements**: Better error handling, connection management
- **Documentation**: Examples, guides, API docs
- **Testing**: More comprehensive test coverage

## Discord API Guidelines

### API Version

- We target Discord API v10
- Follow Discord's official documentation
- Respect rate limiting and best practices

### Implementation Priorities

1. **Core functionality**: REST API, Gateway, basic bot operations
2. **Modern features**: Slash commands, interactions, components
3. **Advanced features**: Voice, threads, webhooks
4. **Convenience methods**: Helper functions, utilities

### Error Handling

- Use appropriate custom exceptions (`Discord::APIError`, etc.)
- Provide helpful error messages with context
- Handle rate limiting gracefully
- Log errors appropriately (without exposing tokens)

## Security Considerations

### Token Safety

- Never commit Discord tokens to the repository
- Use environment variables for sensitive data
- Validate token formats
- Implement secure logging (mask sensitive information)

### Input Validation

- Sanitize user inputs before sending to Discord API
- Validate Discord ID formats
- Check message content length limits
- Prevent injection attacks

## Performance Guidelines

### Threading

- Use thread-safe data structures (`Concurrent::Hash`)
- Handle exceptions in threaded event handlers
- Avoid blocking the main thread
- Test concurrent usage patterns

### Memory Management

- Monitor memory usage in long-running bots
- Clean up resources properly
- Use connection pooling where appropriate
- Implement efficient event dispatching

## Testing Guidelines

### Unit Tests

```ruby
# Test public methods
describe "#method_name" do
  it "does something specific" do
    expect(subject.method_name(args)).to eq(expected)
  end
end

# Mock HTTP requests
stub_request(:get, "https://discord.com/api/v10/endpoint")
  .to_return(status: 200, body: '{"data": "response"}')

# Test error conditions
expect { subject.method_name }.to raise_error(Discord::APIError)
```

### Integration Tests

- Test complete workflows when possible
- Use realistic Discord API responses
- Cover error scenarios and edge cases
- Test thread safety for concurrent operations

## Documentation Guidelines

### YARD Format

```ruby
# Description of what the method does
#
# @param param_name [Type] Description of parameter
# @param optional_param [Type, nil] Optional parameter description
# @return [Type] Description of return value
# @raise [ExceptionType] When this exception is raised
#
# @example Basic usage
#   client.method_name("param_value")
#   #=> expected_result
#
# @example With options
#   client.method_name("param", option: true)
#   #=> expected_result
def method_name(param_name, optional_param: nil)
  # implementation
end
```

### Examples

- Use realistic Discord IDs (18-19 digit snowflakes)
- Show common use cases
- Include error handling examples
- Keep examples focused and concise

## Release Process

Releases are handled by maintainers, but contributors should:

- Update CHANGELOG.md for significant changes
- Follow semantic versioning principles
- Test with multiple Ruby versions
- Ensure all CI checks pass

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Create a GitHub Issue
- **Chat**: Join our Discord server (link in README)
- **Security**: Email security issues privately

## Recognition

All contributors are recognized in our CHANGELOG.md and commit history. Thank you for helping make Discord Ruby better!