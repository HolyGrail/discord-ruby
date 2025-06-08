# frozen_string_literal: true

require "spec_helper"

RSpec.describe Discord::Gateway do
  let(:client) { double("client") }
  let(:token) { "test_token" }
  let(:intents) { 123 }
  let(:gateway) { described_class.new(client, token, intents) }

  describe "#initialize" do
    it "sets up gateway with client, token, and intents" do
      expect(gateway.instance_variable_get(:@client)).to eq(client)
      expect(gateway.instance_variable_get(:@token)).to eq(token)
      expect(gateway.instance_variable_get(:@intents)).to eq(intents)
    end

    it "initializes with default values" do
      expect(gateway.session_id).to be_nil
      expect(gateway.sequence).to be_nil
      expect(gateway.instance_variable_get(:@ready)).to be false
    end
  end

  describe "#send_payload" do
    let(:mock_ws) { double("websocket") }

    before do
      gateway.instance_variable_set(:@ws, mock_ws)
    end

    it "sends JSON payload with opcode" do
      expect(mock_ws).to receive(:send).with('{"op":1}')
      gateway.send_payload(1)
    end

    it "sends JSON payload with opcode and data" do
      data = {test: "data"}
      expected_json = '{"op":1,"d":{"test":"data"}}'
      expect(mock_ws).to receive(:send).with(expected_json)
      gateway.send_payload(1, data)
    end
  end

  describe "#identify" do
    let(:mock_ws) { double("websocket") }

    before do
      gateway.instance_variable_set(:@ws, mock_ws)
    end

    it "sends identify payload with correct structure" do
      expected_payload = {
        op: 2,
        d: {
          token: token,
          intents: intents,
          properties: {
            os: RUBY_PLATFORM,
            browser: "discord-ruby",
            device: "discord-ruby"
          },
          compress: true,
          large_threshold: 250
        }
      }

      expect(mock_ws).to receive(:send).with(JSON.generate(expected_payload))
      gateway.identify
    end
  end

  describe "#heartbeat" do
    let(:mock_ws) { double("websocket") }

    before do
      gateway.instance_variable_set(:@ws, mock_ws)
      gateway.instance_variable_set(:@sequence, 42)
    end

    it "sends heartbeat with current sequence" do
      expected_payload = {op: 1, d: 42}
      expect(mock_ws).to receive(:send).with(JSON.generate(expected_payload))
      gateway.heartbeat
    end
  end

  describe "#update_presence" do
    let(:mock_ws) { double("websocket") }

    before do
      gateway.instance_variable_set(:@ws, mock_ws)
    end

    it "sends presence update with default status" do
      expected_payload = {
        op: 3,
        d: {
          since: nil,
          activities: [],
          status: "online",
          afk: false
        }
      }

      expect(mock_ws).to receive(:send).with(JSON.generate(expected_payload))
      gateway.update_presence
    end

    it "sends presence update with custom activity" do
      activity = {name: "with Ruby", type: 0}
      expected_payload = {
        op: 3,
        d: {
          since: nil,
          activities: [activity],
          status: "dnd",
          afk: false
        }
      }

      expect(mock_ws).to receive(:send).with(JSON.generate(expected_payload))
      gateway.update_presence(status: "dnd", activity: activity)
    end
  end
end
