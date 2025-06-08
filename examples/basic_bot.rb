#!/usr/bin/env ruby
# frozen_string_literal: true

require "discord"

# Create a new Discord client with your bot token
#
# Gateway Intents explained:
# - 0: No privileged intents (sufficient for basic bots)
# - MESSAGE_CONTENT (32768): Required for verified bots to read message content
# - 3276799: All intents (for testing - not recommended for production)
#
# For verified bots, enable MESSAGE_CONTENT intent in Discord Developer Portal:
# Bot Settings > Privileged Gateway Intents > Message Content Intent
MESSAGE_CONTENT_INTENT = 1 << 15  # 32768
GUILD_MESSAGES_INTENT = 1 << 9    # 512

client = Discord::Client.new(
  token: ENV["DISCORD_BOT_TOKEN"],
  intents: GUILD_MESSAGES_INTENT | MESSAGE_CONTENT_INTENT
)

# Event: Bot is ready
client.on(:ready) do |event|
  puts "Bot is ready!"
  puts "Username: #{event[:user][:username]}"
  puts "ID: #{event[:user][:id]}"
  puts "Connected to #{event[:guilds].size} guilds"
end

# Event: New message
client.on(:message_create) do |message|
  # Ignore messages from the bot itself
  next if message[:author][:id] == client.user[:id]

  # Simple ping-pong command
  if message[:content] == "!ping"
    client.send_message(message[:channel_id], content: "Pong!")
  end

  # Echo command
  if message[:content].start_with?("!echo ")
    text = message[:content].sub("!echo ", "")
    client.send_message(message[:channel_id], content: text)
  end

  # Embed example command
  if message[:content] == "!embed"
    embed = {
      title: "Example Embed",
      description: "This is a test embed created with discord-ruby",
      color: 0x00ff00,
      timestamp: Time.now.utc.iso8601,
      footer: {
        text: "Powered by discord-ruby"
      },
      fields: [
        {
          name: "Field 1",
          value: "This is inline",
          inline: true
        },
        {
          name: "Field 2",
          value: "This is also inline",
          inline: true
        }
      ]
    }
    client.send_message(message[:channel_id], embeds: [embed])
  end

  # React to messages containing "hello"
  if message[:content].downcase.include?("hello")
    client.create_reaction(message[:channel_id], message[:id], "👋")
  end
end

# Event: Member joins a guild
client.on(:guild_member_add) do |member|
  puts "New member joined: #{member[:user][:username]}"
end

# Event: Typing start
client.on(:typing_start) do |event|
  puts "#{event[:member][:user][:username]} is typing in channel #{event[:channel_id]}"
end

# Error handling
begin
  # Start the bot
  puts "Starting bot..."
  client.run

  # Keep the bot running
  sleep
rescue Interrupt
  puts "\nShutting down..."
  client.stop
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
end
