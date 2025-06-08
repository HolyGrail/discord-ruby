# Discord Ruby

A powerful and easy-to-use Ruby library for interacting with the Discord API. This gem provides a clean interface for building Discord bots with support for real-time events via WebSocket and REST API operations.

## Features

- Full Discord API v10 support
- WebSocket Gateway connection with automatic reconnection
- Comprehensive REST API client
- Thread-safe event handling system
- Easy-to-use API design
- Built-in error handling and rate limiting

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'discord-ruby'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install discord-ruby
```

## Getting Started

### Prerequisites

Before you begin, you'll need:
1. A Discord account
2. A Discord bot token (create one at https://discord.com/developers/applications)
3. Ruby 3.3 or higher

### Quick Start

Here's a simple example to get you started:

```ruby
require 'discord'

# Create a new client with your bot token
client = Discord::Client.new(token: ENV['DISCORD_BOT_TOKEN'])

# Listen for the ready event
client.on(:ready) do |event|
  puts "Logged in as #{event[:user][:username]}##{event[:user][:discriminator]}"
end

# Listen for messages
client.on(:message_create) do |message|
  # Ignore messages from the bot itself
  next if message[:author][:bot]
  
  # Simple ping command
  if message[:content] == '!ping'
    client.send_message(message[:channel_id], content: 'Pong!')
  end
end

# Start the bot
client.run

# Keep the bot running
sleep
```

### Setting Up Your Bot

1. **Create a Discord Application**
   - Go to https://discord.com/developers/applications
   - Click "New Application"
   - Give your application a name

2. **Create a Bot User**
   - In your application settings, go to the "Bot" section
   - Click "Add Bot"
   - Copy your bot token (keep it secret!)

3. **Invite Your Bot to a Server**
   - In the "OAuth2" section, select "bot" scope
   - Select the permissions your bot needs
   - Use the generated URL to invite your bot

4. **Set Your Bot Token**
   ```bash
   export DISCORD_BOT_TOKEN="your-bot-token-here"
   ```

### Basic Concepts

#### Events

The Discord gem uses an event-driven architecture. You can listen to various events:

```ruby
# User joins a server
client.on(:guild_member_add) do |member|
  puts "#{member[:user][:username]} joined the server!"
end

# Message is deleted
client.on(:message_delete) do |message|
  puts "A message was deleted in channel #{message[:channel_id]}"
end

# User starts typing
client.on(:typing_start) do |event|
  puts "Someone is typing in channel #{event[:channel_id]}"
end
```

#### Sending Messages

```ruby
# Simple text message
client.send_message(channel_id, content: "Hello, Discord!")

# Message with embed
embed = {
  title: "Example Embed",
  description: "This is a rich embed",
  color: 0x00ff00,
  fields: [
    { name: "Field 1", value: "Value 1", inline: true },
    { name: "Field 2", value: "Value 2", inline: true }
  ]
}
client.send_message(channel_id, embed: embed)
```

#### Working with Reactions

```ruby
# Add a reaction
client.create_reaction(channel_id, message_id, "👍")

# Remove a reaction
client.delete_reaction(channel_id, message_id, "👍")
```

#### Fetching Information

```ruby
# Get channel info
channel = client.get_channel(channel_id)

# Get guild info
guild = client.get_guild(guild_id)

# Get user info
user = client.get_user(user_id)
```

### Advanced Usage

#### Custom Intents

Discord uses intents to control which events your bot receives:

```ruby
# Calculate intents (see Discord docs for values)
intents = 1 << 0  # GUILDS
intents |= 1 << 9  # GUILD_MESSAGES
intents |= 1 << 15 # MESSAGE_CONTENT

client = Discord::Client.new(
  token: ENV['DISCORD_BOT_TOKEN'],
  intents: intents
)
```

#### Error Handling

```ruby
begin
  client.send_message(channel_id, content: "Hello!")
rescue Discord::APIError => e
  puts "API Error: #{e.message}"
rescue Discord::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
end
```

#### Updating Presence

```ruby
# Set bot status
client.update_presence(
  status: "online",  # online, dnd, idle, invisible
  activity: {
    name: "with Ruby",
    type: 0  # 0: Playing, 1: Streaming, 2: Listening, 3: Watching
  }
)
```

## Examples

Check out the `examples/` directory for more detailed examples:
- `basic_bot.rb` - A simple bot with basic commands
- More examples coming soon!

## API Documentation

For detailed API documentation, run:

```bash
bundle exec yard
```

Then open `doc/index.html` in your browser.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/HolyGrail/discord-ruby.
