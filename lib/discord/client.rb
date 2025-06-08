# frozen_string_literal: true

require "forwardable"

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
    # @param embed [Hash, nil] Rich embed object
    # @return [Hash] The created message object
    # @raise [Discord::APIError] if the request fails
    #
    # @example Send a simple text message
    #   client.send_message("123456789", content: "Hello, world!")
    #
    # @example Send a message with an embed
    #   embed = {
    #     title: "Example Embed",
    #     description: "This is a test embed",
    #     color: 0x00ff00
    #   }
    #   client.send_message("123456789", embed: embed)
    def send_message(channel_id, content: nil, embed: nil)
      payload = {}
      payload[:content] = content if content
      payload[:embed] = embed if embed

      @http.post("/channels/#{channel_id}/messages", payload)
    end

    def delete_message(channel_id, message_id)
      @http.delete("/channels/#{channel_id}/messages/#{message_id}")
    end

    def edit_message(channel_id, message_id, content: nil, embed: nil)
      payload = {}
      payload[:content] = content if content
      payload[:embed] = embed if embed

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

    def delete_reaction(channel_id, message_id, emoji, user_id = "@me")
      emoji_encoded = URI.encode_www_form_component(emoji)
      @http.delete("/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji_encoded}/#{user_id}")
    end

    def get_channel(channel_id)
      @http.get("/channels/#{channel_id}")
    end

    def get_guild(guild_id)
      @http.get("/guilds/#{guild_id}")
    end

    def get_user(user_id)
      @http.get("/users/#{user_id}")
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
