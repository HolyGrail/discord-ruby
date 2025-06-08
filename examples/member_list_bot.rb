#!/usr/bin/env ruby
# frozen_string_literal: true

require "discord"

# Example bot for getting Discord server member list
#
# Required Bot Permissions:
# - Read Messages/View Channels
# - View Server Insight (for member list)
#
# Required Gateway Intents:
# - GUILD_MEMBERS (1 << 1 = 2) - Required for member list access

GUILD_MEMBERS_INTENT = 1 << 1  # 2

client = Discord::Client.new(
  token: ENV["DISCORD_BOT_TOKEN"],
  intents: GUILD_MEMBERS_INTENT
)

client.on(:ready) do |event|
  puts "Bot is ready!"
  puts "Username: #{event[:user][:username]}"
  puts "Connected to #{event[:guilds].size} guilds"
end

client.on(:message_create) do |message|
  # Ignore messages from the bot itself
  next if message[:author][:id] == client.user[:id]

  # Command to get member count
  if message[:content] == "!membercount"
    begin
      guild_id = message[:guild_id]
      guild = client.get_guild(guild_id)

      client.send_message(
        message[:channel_id],
        content: "📊 Server has #{guild[:approximate_member_count]} members"
      )
    rescue Discord::APIError => e
      client.send_message(
        message[:channel_id],
        content: "❌ Error getting member count: #{e.message}"
      )
    end
  end

  # Command to get first 10 members
  if message[:content] == "!members"
    begin
      guild_id = message[:guild_id]
      members = client.list_guild_members(guild_id, limit: 10)

      member_list = members.map.with_index(1) do |member, index|
        user = member[:user]
        nickname = member[:nick] || user[:username]
        "#{index}. #{nickname} (#{user[:username]}##{user[:discriminator]})"
      end.join("\n")

      embed = {
        title: "👥 First 10 Server Members",
        description: member_list,
        color: 0x00ff00,
        footer: {
          text: "Use !allmembers to get complete list"
        }
      }

      client.send_message(message[:channel_id], embeds: [embed])
    rescue Discord::APIError => e
      client.send_message(
        message[:channel_id],
        content: "❌ Error getting members: #{e.message}"
      )
    end
  end

  # Command to get all members (paginated)
  if message[:content] == "!allmembers"
    begin
      guild_id = message[:guild_id]

      # Send initial message
      status_message = client.send_message(
        message[:channel_id],
        content: "📥 Fetching all members... This may take a while."
      )

      all_members = []
      after = nil
      page = 1

      loop do
        # Update status every 10 pages
        if page % 10 == 0
          client.edit_message(
            message[:channel_id],
            status_message[:id],
            content: "📥 Fetching members... Page #{page} (#{all_members.size} members so far)"
          )
        end

        batch = client.list_guild_members(guild_id, limit: 1000, after: after)
        break if batch.empty?

        all_members.concat(batch)
        after = batch.last[:user][:id]
        page += 1

        # Rate limiting - wait a bit between requests
        sleep(0.5)
      end

      # Create summary
      online_members = all_members.count { |m| m[:user][:bot] != true }
      bot_members = all_members.count { |m| m[:user][:bot] == true }

      embed = {
        title: "👥 Complete Member List",
        fields: [
          {
            name: "📊 Statistics",
            value: [
              "**Total Members:** #{all_members.size}",
              "**Human Members:** #{online_members}",
              "**Bot Members:** #{bot_members}"
            ].join("\n"),
            inline: false
          },
          {
            name: "ℹ️ Export Options",
            value: "Use `!export csv` to get member data as CSV format",
            inline: false
          }
        ],
        color: 0x00ff00,
        timestamp: Time.now.utc.iso8601
      }

      client.edit_message(
        message[:channel_id],
        status_message[:id],
        content: nil,
        embeds: [embed]
      )
    rescue Discord::APIError => e
      client.send_message(
        message[:channel_id],
        content: "❌ Error getting all members: #{e.message}"
      )
    end
  end

  # Command to search members
  if message[:content].start_with?("!search ")
    query = message[:content].sub("!search ", "")

    if query.length < 2
      client.send_message(
        message[:channel_id],
        content: "❌ Search query must be at least 2 characters long"
      )
      next
    end

    begin
      guild_id = message[:guild_id]
      members = client.search_guild_members(guild_id, query, limit: 20)

      if members.empty?
        client.send_message(
          message[:channel_id],
          content: "❌ No members found matching '#{query}'"
        )
      else
        member_list = members.map.with_index(1) do |member, index|
          user = member[:user]
          nickname = member[:nick] || user[:username]
          "#{index}. #{nickname} (#{user[:username]}##{user[:discriminator]})"
        end.join("\n")

        embed = {
          title: "🔍 Search Results for '#{query}'",
          description: member_list,
          color: 0x0099ff,
          footer: {
            text: "Showing up to 20 results"
          }
        }

        client.send_message(message[:channel_id], embeds: [embed])
      end
    rescue Discord::APIError => e
      client.send_message(
        message[:channel_id],
        content: "❌ Error searching members: #{e.message}"
      )
    end
  end

  # Help command
  if message[:content] == "!help"
    embed = {
      title: "🤖 Member List Bot Commands",
      fields: [
        {
          name: "!membercount",
          value: "Shows total member count",
          inline: true
        },
        {
          name: "!members",
          value: "Shows first 10 members",
          inline: true
        },
        {
          name: "!allmembers",
          value: "Gets complete member list",
          inline: true
        },
        {
          name: "!search <query>",
          value: "Search members by name",
          inline: true
        },
        {
          name: "!help",
          value: "Shows this help message",
          inline: true
        }
      ],
      color: 0xffd700,
      footer: {
        text: "Note: Bot needs GUILD_MEMBERS intent and appropriate permissions"
      }
    }

    client.send_message(message[:channel_id], embeds: [embed])
  end
end

# Error handling
begin
  puts "Starting member list bot..."
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
