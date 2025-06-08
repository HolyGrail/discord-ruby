# frozen_string_literal: true

require "websocket-client-simple"
require "json"
require "zlib"
require "stringio"

module Discord
  # WebSocket Gateway connection handler for Discord
  #
  # @api private
  class Gateway
    GATEWAY_VERSION = 10
    GATEWAY_URL = "wss://gateway.discord.gg/?v=#{GATEWAY_VERSION}&encoding=json"

    OPCODES = {
      dispatch: 0,
      heartbeat: 1,
      identify: 2,
      presence_update: 3,
      voice_state_update: 4,
      resume: 6,
      reconnect: 7,
      request_guild_members: 8,
      invalid_session: 9,
      hello: 10,
      heartbeat_ack: 11
    }.freeze

    attr_reader :session_id, :sequence

    # Creates a new Gateway connection
    #
    # @param client [Discord::Client] Parent client instance
    # @param token [String] Discord bot token
    # @param intents [Integer] Gateway intents
    def initialize(client, token, intents)
      @client = client
      @token = token
      @intents = intents
      @ws = nil
      @heartbeat_thread = nil
      @heartbeat_interval = nil
      @heartbeat_ack = true
      @sequence = nil
      @session_id = nil
      @ready = false
      @zlib_stream = nil
    end

    # Connects to the Discord Gateway
    #
    # @return [void]
    def connect
      @ws = WebSocket::Client::Simple.connect(GATEWAY_URL)
      setup_handlers
    end

    # Disconnects from the Discord Gateway
    #
    # @return [void]
    def disconnect
      @heartbeat_thread&.kill
      @ws&.close
      @ws = nil
      @ready = false
    end

    def send_payload(op, data = nil)
      payload = { op: op }
      payload[:d] = data if data
      @ws.send(JSON.generate(payload))
    end

    def identify
      payload = {
        token: @token,
        intents: @intents,
        properties: {
          os: RUBY_PLATFORM,
          browser: "discord-ruby",
          device: "discord-ruby"
        },
        compress: true,
        large_threshold: 250
      }
      send_payload(OPCODES[:identify], payload)
    end

    def heartbeat
      send_payload(OPCODES[:heartbeat], @sequence)
    end

    def update_presence(status: "online", activity: nil)
      payload = {
        since: nil,
        activities: activity ? [activity] : [],
        status: status,
        afk: false
      }
      send_payload(OPCODES[:presence_update], payload)
    end

    private

    def setup_handlers
      @ws.on :open do
        puts "WebSocket connected"
      end

      @ws.on :message do |msg|
        handle_message(msg.data)
      end

      @ws.on :close do |e|
        puts "WebSocket closed: #{e}"
        handle_close
      end

      @ws.on :error do |e|
        puts "WebSocket error: #{e}"
      end
    end

    def handle_message(data)
      if data.is_a?(String)
        message = JSON.parse(data, symbolize_names: true)
      else
        message = decompress_message(data)
      end

      @sequence = message[:s] if message[:s]

      case message[:op]
      when OPCODES[:hello]
        handle_hello(message[:d])
      when OPCODES[:heartbeat_ack]
        @heartbeat_ack = true
      when OPCODES[:dispatch]
        handle_dispatch(message[:t], message[:d])
      when OPCODES[:invalid_session]
        handle_invalid_session(message[:d])
      when OPCODES[:reconnect]
        handle_reconnect
      end
    rescue JSON::ParserError => e
      puts "Failed to parse message: #{e}"
    end

    def decompress_message(data)
      @zlib_stream ||= Zlib::Inflate.new

      begin
        decompressed = @zlib_stream.inflate(data)
        JSON.parse(decompressed, symbolize_names: true)
      rescue Zlib::DataError => e
        puts "Zlib decompression error: #{e}"
        nil
      end
    end

    def handle_hello(data)
      @heartbeat_interval = data[:heartbeat_interval]
      start_heartbeat
      identify
    end

    def handle_dispatch(event_name, data)
      case event_name
      when "READY"
        @session_id = data[:session_id]
        @ready = true
        @client.send(:handle_ready, data)
        @client.emit(:ready, data)
      when "GUILD_CREATE"
        @client.send(:handle_guild_create, data)
        @client.emit(:guild_create, data)
      when "MESSAGE_CREATE"
        @client.emit(:message_create, data)
      when "MESSAGE_UPDATE"
        @client.emit(:message_update, data)
      when "MESSAGE_DELETE"
        @client.emit(:message_delete, data)
      when "CHANNEL_CREATE"
        @client.send(:handle_channel_create, data)
        @client.emit(:channel_create, data)
      when "CHANNEL_UPDATE"
        @client.send(:handle_channel_update, data)
        @client.emit(:channel_update, data)
      when "CHANNEL_DELETE"
        @client.send(:handle_channel_delete, data)
        @client.emit(:channel_delete, data)
      when "GUILD_MEMBER_ADD"
        @client.emit(:guild_member_add, data)
      when "GUILD_MEMBER_UPDATE"
        @client.emit(:guild_member_update, data)
      when "GUILD_MEMBER_REMOVE"
        @client.emit(:guild_member_remove, data)
      when "GUILD_ROLE_CREATE"
        @client.emit(:guild_role_create, data)
      when "GUILD_ROLE_UPDATE"
        @client.emit(:guild_role_update, data)
      when "GUILD_ROLE_DELETE"
        @client.emit(:guild_role_delete, data)
      when "VOICE_STATE_UPDATE"
        @client.emit(:voice_state_update, data)
      when "PRESENCE_UPDATE"
        @client.emit(:presence_update, data)
      when "TYPING_START"
        @client.emit(:typing_start, data)
      when "USER_UPDATE"
        @client.emit(:user_update, data)
      else
        @client.emit(event_name.downcase.to_sym, data)
      end
    end

    def handle_invalid_session(resumable)
      if resumable
        resume
      else
        @session_id = nil
        @sequence = nil
        sleep(1 + rand(5))
        identify
      end
    end

    def handle_reconnect
      disconnect
      sleep(1 + rand(5))
      connect
    end

    def handle_close
      @heartbeat_thread&.kill
      @heartbeat_thread = nil
    end

    def start_heartbeat
      @heartbeat_thread&.kill
      @heartbeat_thread = Thread.new do
        loop do
          if @heartbeat_ack
            @heartbeat_ack = false
            heartbeat
          else
            puts "Heartbeat ACK not received, reconnecting..."
            disconnect
            connect
            break
          end
          sleep(@heartbeat_interval / 1000.0)
        end
      end
    end

    def resume
      payload = {
        token: @token,
        session_id: @session_id,
        seq: @sequence
      }
      send_payload(OPCODES[:resume], payload)
    end
  end
end