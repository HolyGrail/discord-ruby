# frozen_string_literal: true

require "spec_helper"

RSpec.describe Discord::HTTP do
  let(:token) { "test_token" }
  let(:http) { described_class.new(token) }

  describe "#initialize" do
    it "sets up headers with the token" do
      headers = http.instance_variable_get(:@headers)
      expect(headers["Authorization"]).to eq("Bot #{token}")
      expect(headers["User-Agent"]).to include("DiscordBot")
      expect(headers["Content-Type"]).to eq("application/json")
    end
  end

  describe "#get" do
    it "makes a GET request" do
      stub_request(:get, "https://discord.com/api/v10/users/@me")
        .with(headers: {"Authorization" => "Bot test_token"})
        .to_return(status: 200, body: '{"id": "123", "username": "TestBot"}')

      result = http.get("/users/@me")
      expect(result).to eq({id: "123", username: "TestBot"})
    end
  end

  describe "#post" do
    it "makes a POST request with JSON payload" do
      payload = {content: "Hello, world!"}

      stub_request(:post, "https://discord.com/api/v10/channels/123/messages")
        .with(
          body: payload.to_json,
          headers: {"Authorization" => "Bot test_token", "Content-Type" => "application/json"}
        )
        .to_return(status: 200, body: '{"id": "456", "content": "Hello, world!"}')

      result = http.post("/channels/123/messages", payload)
      expect(result).to eq({id: "456", content: "Hello, world!"})
    end
  end

  describe "#patch" do
    it "makes a PATCH request" do
      payload = {content: "Updated message"}

      stub_request(:patch, "https://discord.com/api/v10/channels/123/messages/456")
        .with(body: payload.to_json)
        .to_return(status: 200, body: '{"id": "456", "content": "Updated message"}')

      result = http.patch("/channels/123/messages/456", payload)
      expect(result).to eq({id: "456", content: "Updated message"})
    end
  end

  describe "#put" do
    it "makes a PUT request" do
      stub_request(:put, "https://discord.com/api/v10/channels/123/messages/456/reactions/👍/@me")
        .to_return(status: 204, body: "")

      result = http.put("/channels/123/messages/456/reactions/👍/@me")
      expect(result).to be_nil
    end
  end

  describe "#delete" do
    it "makes a DELETE request" do
      stub_request(:delete, "https://discord.com/api/v10/channels/123/messages/456")
        .to_return(status: 204, body: "")

      result = http.delete("/channels/123/messages/456")
      expect(result).to be_nil
    end
  end

  describe "error handling" do
    it "raises AuthenticationError for 401 responses" do
      stub_request(:get, "https://discord.com/api/v10/users/@me")
        .to_return(status: 401, body: '{"message": "401: Unauthorized"}')

      expect { http.get("/users/@me") }.to raise_error(Discord::AuthenticationError, "Invalid token")
    end

    it "raises APIError for 400 responses" do
      stub_request(:post, "https://discord.com/api/v10/channels/123/messages")
        .to_return(status: 400, body: '{"message": "Invalid request", "code": 50035}')

      expect { http.post("/channels/123/messages", {}) }
        .to raise_error(Discord::APIError, "Discord API Error (50035): Invalid request")
    end

    it "raises APIError for 403 responses" do
      stub_request(:get, "https://discord.com/api/v10/channels/123")
        .to_return(status: 403, body: '{"message": "Missing permissions", "code": 50001}')

      expect { http.get("/channels/123") }
        .to raise_error(Discord::APIError, "Discord API Error (50001): Missing permissions")
    end

    it "raises APIError for 404 responses" do
      stub_request(:get, "https://discord.com/api/v10/channels/999")
        .to_return(status: 404, body: '{"message": "Unknown Channel", "code": 10003}')

      expect { http.get("/channels/999") }
        .to raise_error(Discord::APIError, "Discord API Error (10003): Unknown Channel")
    end

    it "handles rate limiting" do
      stub_request(:post, "https://discord.com/api/v10/channels/123/messages")
        .to_return(status: 429, headers: {"Retry-After" => "2.5"}, body: "")

      expect { http.post("/channels/123/messages", {}) }
        .to raise_error(Discord::APIError, "Rate limited. Retry after 2.5 seconds")
    end
  end
end
