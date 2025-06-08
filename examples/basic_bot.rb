#!/usr/bin/env ruby
# frozen_string_literal: true

require "discord"

# Create a new Discord client with your bot token
client = Discord::Client.new(
  token: ENV["DISCORD_BOT_TOKEN"],
  intents: 3276799 # All intents for testing
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
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace
end