# frozen_string_literal: true

require "spec_helper"

RSpec.describe Discord::Client do
  # Valid Discord bot token format for testing (24.6.27 characters)
  let(:token) { "MTIzNDU2Nzg5MDEyMzQ1Njc4.GhI4Jk.L5MnOpQrStUvWxYz0123456789ABC" }
  let(:client) { described_class.new(token: token) }

  describe "#initialize" do
    it "sets the token" do
      expect(client.token).to eq(token)
    end

    it "initializes with default intents" do
      expect(client.instance_variable_get(:@intents)).to eq(0)
    end

    it "accepts custom intents" do
      client_with_intents = described_class.new(token: token, intents: 123)
      expect(client_with_intents.instance_variable_get(:@intents)).to eq(123)
    end

    it "creates an HTTP client" do
      expect(client.http).to be_a(Discord::HTTP)
    end

    it "creates an Events handler" do
      expect(client.events).to be_a(Discord::Events)
    end

    it "starts as not ready" do
      expect(client).not_to be_ready
    end

    it "validates token format" do
      expect { described_class.new(token: "invalid_token") }
        .to raise_error(ArgumentError, /Token format appears invalid/)
    end

    it "rejects nil token" do
      expect { described_class.new(token: nil) }
        .to raise_error(ArgumentError, "Token cannot be nil or empty")
    end

    it "rejects empty token" do
      expect { described_class.new(token: "") }
        .to raise_error(ArgumentError, "Token cannot be nil or empty")
    end
  end

  describe "#on" do
    it "delegates to the events handler" do
      handler = proc { |data| puts data }
      expect(client.events).to receive(:on).with(:message_create, &handler)
      client.on(:message_create, &handler)
    end
  end

  describe "#send_message" do
    it "sends a message via HTTP" do
      channel_id = "123456789"
      content = "Hello, world!"

      expect(client.http).to receive(:post)
        .with("/channels/#{channel_id}/messages", {content: content})
        .and_return({id: "987654321", content: content})

      result = client.send_message(channel_id, content: content)
      expect(result).to eq({id: "987654321", content: content})
    end

    it "sends embeds array" do
      channel_id = "123456789"
      embeds = [
        {title: "Test Embed 1", description: "First embed"},
        {title: "Test Embed 2", description: "Second embed"}
      ]

      expect(client.http).to receive(:post)
        .with("/channels/#{channel_id}/messages", {embeds: embeds})

      client.send_message(channel_id, embeds: embeds)
    end

    it "sends a single embed as array" do
      channel_id = "123456789"
      embed = {title: "Test Embed", description: "This is a test"}

      expect(client.http).to receive(:post)
        .with("/channels/#{channel_id}/messages", {embeds: [embed]})

      client.send_message(channel_id, embeds: [embed])
    end
  end

  describe "#delete_message" do
    it "deletes a message via HTTP" do
      channel_id = "123456789"
      message_id = "987654321"

      expect(client.http).to receive(:delete)
        .with("/channels/#{channel_id}/messages/#{message_id}")

      client.delete_message(channel_id, message_id)
    end
  end

  describe "#edit_message" do
    it "edits a message via HTTP" do
      channel_id = "123456789"
      message_id = "987654321"
      new_content = "Edited message"

      expect(client.http).to receive(:patch)
        .with("/channels/#{channel_id}/messages/#{message_id}", {content: new_content})

      client.edit_message(channel_id, message_id, content: new_content)
    end

    it "edits message with embeds" do
      channel_id = "123456789"
      message_id = "987654321"
      embeds = [{title: "Updated Embed", description: "Updated content"}]

      expect(client.http).to receive(:patch)
        .with("/channels/#{channel_id}/messages/#{message_id}", {embeds: embeds})

      client.edit_message(channel_id, message_id, embeds: embeds)
    end

    it "edits message content and embeds" do
      channel_id = "123456789"
      message_id = "987654321"
      content = "Updated message content"
      embeds = [{title: "Updated Embed", description: "Updated embed content"}]

      expect(client.http).to receive(:patch)
        .with("/channels/#{channel_id}/messages/#{message_id}", {content: content, embeds: embeds})

      client.edit_message(channel_id, message_id, content: content, embeds: embeds)
    end
  end

  describe "#create_reaction" do
    it "creates a reaction via HTTP" do
      channel_id = "123456789"
      message_id = "987654321"
      emoji = "👍"

      expect(client.http).to receive(:put)
        .with("/channels/#{channel_id}/messages/#{message_id}/reactions/#{URI.encode_www_form_component(emoji)}/@me")

      client.create_reaction(channel_id, message_id, emoji)
    end
  end

  describe "#get_channel" do
    it "gets channel info via HTTP" do
      channel_id = "123456789"
      channel_data = {id: channel_id, name: "general"}

      expect(client.http).to receive(:get)
        .with("/channels/#{channel_id}")
        .and_return(channel_data)

      result = client.get_channel(channel_id)
      expect(result).to eq(channel_data)
    end
  end

  describe "#get_guild" do
    it "gets guild info via HTTP" do
      guild_id = "123456789"
      guild_data = {id: guild_id, name: "Test Guild"}

      expect(client.http).to receive(:get)
        .with("/guilds/#{guild_id}")
        .and_return(guild_data)

      result = client.get_guild(guild_id)
      expect(result).to eq(guild_data)
    end
  end

  describe "#get_user" do
    it "gets user info via HTTP" do
      user_id = "123456789"
      user_data = {id: user_id, username: "TestUser"}

      expect(client.http).to receive(:get)
        .with("/users/#{user_id}")
        .and_return(user_data)

      result = client.get_user(user_id)
      expect(result).to eq(user_data)
    end
  end
end
