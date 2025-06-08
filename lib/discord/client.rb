# frozen_string_literal: true

require "forwardable"
require "uri"

module Discord
  # Main Discord client class that manages connections and provides API methods
  #
  # @example Creating a new client
  #   client = Discord::Client.new(token: "your-bot-token")
  #
  # @example Listening to events
  #   client.on(:message_create) do |message|
  #     puts "New message: #{message[:content]}"
  #   end
  #
  # @example Starting the bot
  #   client.run
  class Client
    extend Forwardable

    attr_reader :token, :gateway, :http, :events

    def_delegators :@events, :on, :emit

    # Creates a new Discord client
    #
    # @param token [String] Discord bot token
    # @param intents [Integer, nil] Gateway intents (defaults to 0)
    # @raise [ArgumentError] if token is nil or empty
    #
    # @note For verified bots, MESSAGE_CONTENT intent (1 << 15 = 32768) is required
    #   to receive message content. Enable this in Discord Developer Portal under
    #   Bot > Privileged Gateway Intents, and include it in your intents value.
    #
    # @example Basic client without privileged intents
    #   client = Discord::Client.new(token: ENV["DISCORD_BOT_TOKEN"])
    #
    # @example Client with MESSAGE_CONTENT intent for verified bots
    #   MESSAGE_CONTENT_INTENT = 1 << 15  # 32768
    #   client = Discord::Client.new(
    #     token: ENV["DISCORD_BOT_TOKEN"],
    #     intents: MESSAGE_CONTENT_INTENT
    #   )
    def initialize(token:, intents: nil)
      @token = validate_token!(token)
      @intents = intents || 0
      @gateway = nil
      @http = HTTP.new(token)
      @events = Events.new
      @ready = false
    end

    # Starts the bot by connecting to Discord's Gateway
    #
    # @return [void]
    def run
      @gateway = Gateway.new(self, @token, @intents)
      @gateway.connect
    end

    # Stops the bot and disconnects from Discord
    #
    # @return [void]
    def stop
      @gateway&.disconnect
    end

    # Checks if the bot is ready and connected
    #
    # @return [Boolean] true if connected and ready
    def ready?
      @ready
    end

    attr_reader :user

    def guilds
      @guilds ||= {}
    end

    def channels
      @channels ||= {}
    end

    # Sends a message to a channel
    #
    # @param channel_id [String] The channel ID to send the message to
    # @param content [String, nil] The text content of the message
    # @param embeds [Array<Hash>, nil] Array of rich embed objects
    # @return [Hash] The created message object
    # @raise [Discord::APIError] if the request fails
    #
    # @example Send a simple text message
    #   client.send_message("123456789", content: "Hello, world!")
    #
    # @example Send a message with embeds
    #   embeds = [
    #     {
    #       title: "First Embed",
    #       description: "This is the first embed",
    #       color: 0x00ff00
    #     },
    #     {
    #       title: "Second Embed",
    #       description: "This is the second embed",
    #       color: 0x0000ff
    #     }
    #   ]
    #   client.send_message("123456789", embeds: embeds)
    #
    # @example Send a single embed
    #   embed = {
    #     title: "Example Embed",
    #     description: "This is a test embed",
    #     color: 0x00ff00
    #   }
    #   client.send_message("123456789", embeds: [embed])
    def send_message(channel_id, content: nil, embeds: nil)
      payload = {}
      payload[:content] = content if content
      payload[:embeds] = embeds if embeds

      @http.post("/channels/#{channel_id}/messages", payload)
    end

    # Deletes a message
    #
    # @param channel_id [String] The channel ID containing the message
    # @param message_id [String] The message ID to delete
    # @return [nil]
    # @raise [Discord::APIError] if the request fails
    def delete_message(channel_id, message_id)
      @http.delete("/channels/#{channel_id}/messages/#{message_id}")
    end

    # Edits an existing message
    #
    # @param channel_id [String] The channel ID containing the message
    # @param message_id [String] The message ID to edit
    # @param content [String, nil] The new text content of the message
    # @param embeds [Array<Hash>, nil] Array of rich embed objects
    # @return [Hash] The edited message object
    # @raise [Discord::APIError] if the request fails
    def edit_message(channel_id, message_id, content: nil, embeds: nil)
      payload = {}
      payload[:content] = content if content
      payload[:embeds] = embeds if embeds

      @http.patch("/channels/#{channel_id}/messages/#{message_id}", payload)
    end

    # Creates a reaction on a message
    #
    # @param channel_id [String] The channel ID containing the message
    # @param message_id [String] The message ID to react to
    # @param emoji [String] The emoji to react with (Unicode or custom emoji)
    # @return [nil]
    # @raise [Discord::APIError] if the request fails
    #
    # @example React with a Unicode emoji
    #   client.create_reaction("123456789", "987654321", "👍")
    #
    # @example React with a custom emoji
    #   client.create_reaction("123456789", "987654321", "custom_emoji:123456789")
    def create_reaction(channel_id, message_id, emoji)
      emoji_encoded = URI.encode_www_form_component(emoji)
      @http.put("/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji_encoded}/@me")
    end

    # Deletes a reaction from a message
    #
    # @param channel_id [String] The channel ID containing the message
    # @param message_id [String] The message ID containing the reaction
    # @param emoji [String] The emoji to remove (Unicode or custom emoji)
    # @param user_id [String] The user ID whose reaction to remove (defaults to bot)
    # @return [nil]
    # @raise [Discord::APIError] if the request fails
    #
    # @example Remove bot's own reaction
    #   client.delete_reaction("123456789", "987654321", "👍")
    #
    # @example Remove another user's reaction
    #   client.delete_reaction("123456789", "987654321", "👍", "user_id_here")
    def delete_reaction(channel_id, message_id, emoji, user_id = "@me")
      emoji_encoded = URI.encode_www_form_component(emoji)
      @http.delete("/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji_encoded}/#{user_id}")
    end

    # Gets information about a channel
    #
    # @param channel_id [String] The channel ID to retrieve
    # @return [Hash] The channel object
    # @raise [Discord::APIError] if the request fails
    def get_channel(channel_id)
      @http.get("/channels/#{channel_id}")
    end

    # Gets information about a guild
    #
    # @param guild_id [String] The guild ID to retrieve
    # @return [Hash] The guild object
    # @raise [Discord::APIError] if the request fails
    def get_guild(guild_id)
      @http.get("/guilds/#{guild_id}")
    end

    # Gets information about a user
    #
    # @param user_id [String] The user ID to retrieve
    # @return [Hash] The user object
    # @raise [Discord::APIError] if the request fails
    def get_user(user_id)
      @http.get("/users/#{user_id}")
    end

    # Lists guild members
    #
    # @param guild_id [String] The guild ID to get members from
    # @param limit [Integer] Max number of members to return (1-1000, default 1)
    # @param after [String, nil] User ID to get members after (for pagination)
    # @return [Array<Hash>] Array of guild member objects
    # @raise [Discord::APIError] if the request fails
    #
    # @note Requires GUILD_MEMBERS intent for guilds with >75k members
    #
    # @example Get first 100 members
    #   members = client.list_guild_members("123456789", limit: 100)
    #
    # @example Paginate through all members
    #   members = []
    #   after = nil
    #   loop do
    #     batch = client.list_guild_members("123456789", limit: 1000, after: after)
    #     break if batch.empty?
    #     members.concat(batch)
    #     after = batch.last[:user][:id]
    #   end
    def list_guild_members(guild_id, limit: 1, after: nil)
      params = {limit: limit}
      params[:after] = after if after
      @http.get("/guilds/#{guild_id}/members", params)
    end

    # Gets a specific guild member
    #
    # @param guild_id [String] The guild ID
    # @param user_id [String] The user ID
    # @return [Hash] The guild member object
    # @raise [Discord::APIError] if the request fails
    def get_guild_member(guild_id, user_id)
      @http.get("/guilds/#{guild_id}/members/#{user_id}")
    end

    # Searches guild members by username or nickname
    #
    # @param guild_id [String] The guild ID to search in
    # @param query [String] Query string to match username(s) and nickname(s) against
    # @param limit [Integer] Max number of members to return (1-1000, default 1)
    # @return [Array<Hash>] Array of guild member objects
    # @raise [Discord::APIError] if the request fails
    #
    # @example Search for members with "test" in their name
    #   members = client.search_guild_members("123456789", "test", limit: 10)
    def search_guild_members(guild_id, query, limit: 1)
      params = {query: query, limit: limit}
      @http.get("/guilds/#{guild_id}/members/search", params)
    end

    # Updates the bot's presence/status
    #
    # @param status [String] Status type: "online", "dnd", "idle", or "invisible"
    # @param activity [Hash, nil] Activity object with :name and :type
    # @return [void]
    #
    # @example Set status to Do Not Disturb with a game activity
    #   client.update_presence(
    #     status: "dnd",
    #     activity: { name: "with Ruby", type: 0 }
    #   )
    def update_presence(status: "online", activity: nil)
      @gateway&.update_presence(status: status, activity: activity)
    end

    # Gets all roles in a guild
    #
    # @param guild_id [String] The guild ID
    # @return [Array<Hash>] Array of role objects
    # @raise [Discord::APIError] if the request fails
    def get_guild_roles(guild_id)
      @http.get("/guilds/#{guild_id}/roles")
    end

    # Creates a new role in a guild
    #
    # @param guild_id [String] The guild ID
    # @param name [String] The role name
    # @param permissions [Integer, nil] Role permissions as bitfield
    # @param color [Integer, nil] RGB color value
    # @param hoist [Boolean] Whether the role should be displayed separately
    # @param mentionable [Boolean] Whether the role can be mentioned
    # @return [Hash] The created role object
    # @raise [Discord::APIError] if the request fails
    #
    # @example Create a basic role
    #   role = client.create_guild_role("123456789", "Subscribers")
    #
    # @example Create a role with custom properties
    #   role = client.create_guild_role(
    #     "123456789",
    #     "VIP Members",
    #     color: 0xff0000,
    #     hoist: true,
    #     mentionable: true
    #   )
    def create_guild_role(guild_id, name, permissions: nil, color: nil, hoist: false, mentionable: false)
      payload = {
        name: name,
        hoist: hoist,
        mentionable: mentionable
      }
      payload[:permissions] = permissions.to_s if permissions
      payload[:color] = color if color

      @http.post("/guilds/#{guild_id}/roles", payload)
    end

    # Adds a role to a guild member
    #
    # @param guild_id [String] The guild ID
    # @param user_id [String] The user ID
    # @param role_id [String] The role ID to add
    # @return [nil]
    # @raise [Discord::APIError] if the request fails
    #
    # @example Add a role to a member
    #   client.add_guild_member_role("123456789", "987654321", "555666777")
    def add_guild_member_role(guild_id, user_id, role_id)
      @http.put("/guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}")
    end

    # Removes a role from a guild member
    #
    # @param guild_id [String] The guild ID
    # @param user_id [String] The user ID
    # @param role_id [String] The role ID to remove
    # @return [nil]
    # @raise [Discord::APIError] if the request fails
    def remove_guild_member_role(guild_id, user_id, role_id)
      @http.delete("/guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}")
    end

    # Modifies a guild member (e.g., nickname, roles)
    #
    # @param guild_id [String] The guild ID
    # @param user_id [String] The user ID
    # @param nick [String, nil] New nickname (null to remove)
    # @param roles [Array<String>, nil] Array of role IDs
    # @return [Hash] The modified guild member object
    # @raise [Discord::APIError] if the request fails
    #
    # @example Set nickname and roles
    #   client.modify_guild_member(
    #     "123456789",
    #     "987654321",
    #     nick: "New Nickname",
    #     roles: ["role1", "role2"]
    #   )
    def modify_guild_member(guild_id, user_id, nick: nil, roles: nil)
      payload = {}
      payload[:nick] = nick if !nick.nil?
      payload[:roles] = roles if roles

      @http.patch("/guilds/#{guild_id}/members/#{user_id}", payload)
    end

    private

    def handle_ready(data)
      @ready = true
      @user = data[:user]
      data[:guilds]&.each do |guild|
        @guilds[guild[:id]] = guild
      end
    end

    def handle_guild_create(data)
      @guilds[data[:id]] = data
      data[:channels]&.each do |channel|
        @channels[channel[:id]] = channel
      end
    end

    def handle_channel_create(data)
      @channels[data[:id]] = data
    end

    def handle_channel_update(data)
      @channels[data[:id]] = data
    end

    def handle_channel_delete(data)
      @channels.delete(data[:id])
    end

    # Validates Discord bot token format
    #
    # @param token [String] The token to validate
    # @return [String] The validated token
    # @raise [ArgumentError] if token is invalid
    def validate_token!(token)
      raise ArgumentError, "Token cannot be nil or empty" if token.nil? || token.empty?
      raise ArgumentError, "Token must be a string" unless token.is_a?(String)

      # Basic Discord bot token format validation
      # Tokens should contain 2 dots and be reasonably long
      unless token.match?(/\A[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\z/) && token.length > 50
        raise ArgumentError, "Token format appears invalid (expected Discord bot token format)"
      end

      token
    end
  end
end
