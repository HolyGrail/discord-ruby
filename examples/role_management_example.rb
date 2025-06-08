#!/usr/bin/env ruby
# frozen_string_literal: true

require "discord"

# Example: Role management for external service integration
#
# This example shows how to use Discord Ruby Gem's role management features
# to implement external service integration (like Twitch/YouTube followers).
#
# Required Bot Permissions:
# - Manage Roles
# - Read Messages/View Channels
#
# Required Gateway Intents:
# - GUILD_MEMBERS (for role management)

GUILD_MEMBERS_INTENT = 1 << 1  # 2

client = Discord::Client.new(
  token: ENV["DISCORD_BOT_TOKEN"],
  intents: GUILD_MEMBERS_INTENT
)

# Example role IDs (you'd get these from your server)
FOLLOWER_ROLE_ID = ENV["FOLLOWER_ROLE_ID"]
SUBSCRIBER_ROLE_ID = ENV["SUBSCRIBER_ROLE_ID"]

client.on(:ready) do |event|
  puts "Bot is ready!"
  puts "Username: #{event[:user][:username]}"
  puts "Connected to #{event[:guilds].size} guilds"
end

client.on(:message_create) do |message|
  next if message[:author][:id] == client.user[:id]

  guild_id = message[:guild_id]
  user_id = message[:author][:id]
  content = message[:content]

  # Example: Manual role assignment command
  if content =~ /^!grant (follower|subscriber) <@!?(\d+)>$/
    role_type = $1
    target_user_id = $2

    role_id = case role_type
    when "follower"
      FOLLOWER_ROLE_ID
    when "subscriber"
      SUBSCRIBER_ROLE_ID
    end

    unless role_id
      client.send_message(
        message[:channel_id],
        content: "❌ Role not configured. Set FOLLOWER_ROLE_ID and SUBSCRIBER_ROLE_ID environment variables."
      )
      next
    end

    begin
      # Check if user has permission to grant roles
      member = client.get_guild_member(guild_id, user_id)
      has_admin = member[:roles].any? { |role_id_check|
        role = client.get_guild_roles(guild_id).find { |r| r[:id] == role_id_check }
        role && role[:permissions].to_i & 0x8 != 0  # Administrator permission
      }

      unless has_admin
        client.send_message(
          message[:channel_id],
          content: "❌ You need administrator permissions to grant roles."
        )
        next
      end

      # Grant the role
      client.add_guild_member_role(guild_id, target_user_id, role_id)

      client.send_message(
        message[:channel_id],
        content: "✅ Granted #{role_type} role to <@#{target_user_id}>"
      )
    rescue Discord::APIError => e
      client.send_message(
        message[:channel_id],
        content: "❌ Error granting role: #{e.message}"
      )
    end
  end

  # Example: Check user's roles
  if content == "!myroles"
    begin
      member = client.get_guild_member(guild_id, user_id)
      roles = client.get_guild_roles(guild_id)

      user_roles = member[:roles].map do |role_id|
        role = roles.find { |r| r[:id] == role_id }
        role ? role[:name] : "Unknown Role"
      end

      if user_roles.empty?
        client.send_message(
          message[:channel_id],
          content: "You don't have any roles in this server."
        )
      else
        embed = {
          title: "Your Roles",
          description: user_roles.join("\n"),
          color: 0x00ff00
        }

        client.send_message(message[:channel_id], embeds: [embed])
      end
    rescue Discord::APIError => e
      client.send_message(
        message[:channel_id],
        content: "❌ Error fetching roles: #{e.message}"
      )
    end
  end

  # Example: Create roles (admin only)
  if content =~ /^!createrole (.+)$/
    role_name = $1.strip

    begin
      # Check admin permission
      member = client.get_guild_member(guild_id, user_id)
      has_admin = member[:roles].any? { |role_id_check|
        role = client.get_guild_roles(guild_id).find { |r| r[:id] == role_id_check }
        role && role[:permissions].to_i & 0x8 != 0
      }

      unless has_admin
        client.send_message(
          message[:channel_id],
          content: "❌ You need administrator permissions to create roles."
        )
        next
      end

      # Create the role
      role = client.create_guild_role(
        guild_id,
        role_name,
        color: 0x00ff88,
        hoist: true,
        mentionable: true
      )

      client.send_message(
        message[:channel_id],
        content: "✅ Created role: **#{role[:name]}** (ID: #{role[:id]})"
      )
    rescue Discord::APIError => e
      client.send_message(
        message[:channel_id],
        content: "❌ Error creating role: #{e.message}"
      )
    end
  end

  # Help command
  if content == "!help"
    embed = {
      title: "🎭 Role Management Bot",
      description: "Example bot showing Discord Ruby Gem role management features",
      fields: [
        {
          name: "!myroles",
          value: "Show your current roles",
          inline: true
        },
        {
          name: "!grant <type> @user",
          value: "Grant role to user (admin only)",
          inline: true
        },
        {
          name: "!createrole <name>",
          value: "Create new role (admin only)",
          inline: true
        }
      ],
      color: 0x0099ff,
      footer: {
        text: "For external service integration, implement your own logic using these role management functions"
      }
    }

    client.send_message(message[:channel_id], embeds: [embed])
  end
end

# Example function showing how you might implement external service checking
# (You would implement the actual service checking logic)
def check_external_service_status(user_identifier, service_type)
  # This is where you'd implement calls to Twitch API, YouTube API, etc.
  # Example return value:
  {
    follower: false,
    subscriber: true,
    vip: false
  }
end

# Example function for bulk role updates based on external service status
def update_user_roles_based_on_external_service(client, guild_id, user_mappings)
  # user_mappings: Hash of discord_user_id => { service_type => service_user_id }

  user_mappings.each do |discord_user_id, mappings|
    member = client.get_guild_member(guild_id, discord_user_id)
    current_roles = member[:roles] || []

    mappings.each do |service_type, service_user_id|
      # Check status with your external service
      status = check_external_service_status(service_user_id, service_type)

      # Example: Grant follower role if user is following
      if status[:follower] && !current_roles.include?(FOLLOWER_ROLE_ID)
        client.add_guild_member_role(guild_id, discord_user_id, FOLLOWER_ROLE_ID)
        puts "Added follower role to #{discord_user_id}"
      elsif !status[:follower] && current_roles.include?(FOLLOWER_ROLE_ID)
        client.remove_guild_member_role(guild_id, discord_user_id, FOLLOWER_ROLE_ID)
        puts "Removed follower role from #{discord_user_id}"
      end

      # Example: Grant subscriber role if user is subscribed
      if status[:subscriber] && !current_roles.include?(SUBSCRIBER_ROLE_ID)
        client.add_guild_member_role(guild_id, discord_user_id, SUBSCRIBER_ROLE_ID)
        puts "Added subscriber role to #{discord_user_id}"
      elsif !status[:subscriber] && current_roles.include?(SUBSCRIBER_ROLE_ID)
        client.remove_guild_member_role(guild_id, discord_user_id, SUBSCRIBER_ROLE_ID)
        puts "Removed subscriber role from #{discord_user_id}"
      end
    end

    # Rate limiting
    sleep(0.1)
  rescue Discord::APIError => e
    puts "Error updating roles for #{discord_user_id}: #{e.message}"
  end
end

# Error handling
begin
  puts "Starting role management example bot..."
  puts ""
  puts "This example shows how to use Discord Ruby Gem for role management."
  puts "For external service integration, you would:"
  puts "1. Implement your own external service API calls"
  puts "2. Use the role management functions provided by this gem"
  puts "3. Create periodic jobs to sync roles based on external service status"
  puts ""

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
