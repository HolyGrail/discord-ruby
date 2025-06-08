# frozen_string_literal: true

require "spec_helper"

RSpec.describe Discord::Events do
  let(:events) { described_class.new }

  describe "#on" do
    it "registers an event handler" do
      handler = proc { |data| data }
      events.on(:test_event, &handler)
      
      expect(events.handlers_for(:test_event)).to include(handler)
    end

    it "raises an error if no block is given" do
      expect { events.on(:test_event) }.to raise_error(ArgumentError, "Block is required")
    end

    it "allows multiple handlers for the same event" do
      handler1 = proc { |data| data }
      handler2 = proc { |data| data * 2 }
      
      events.on(:test_event, &handler1)
      events.on(:test_event, &handler2)
      
      expect(events.handlers_for(:test_event).size).to eq(2)
    end
  end

  describe "#emit" do
    it "calls all registered handlers" do
      results = []
      
      events.on(:test_event) { |data| results << "handler1: #{data}" }
      events.on(:test_event) { |data| results << "handler2: #{data}" }
      
      events.emit(:test_event, "test")
      sleep 0.1 # Allow threads to complete
      
      expect(results).to contain_exactly("handler1: test", "handler2: test")
    end

    it "handles errors in event handlers gracefully" do
      events.on(:test_event) { raise "Test error" }
      events.on(:test_event) { |data| data }
      
      expect { events.emit(:test_event, "test") }.not_to raise_error
    end

    it "does nothing if no handlers are registered" do
      expect { events.emit(:nonexistent_event, "test") }.not_to raise_error
    end
  end

  describe "#remove" do
    it "removes a specific handler" do
      handler1 = proc { |data| data }
      handler2 = proc { |data| data * 2 }
      
      events.on(:test_event, &handler1)
      events.on(:test_event, &handler2)
      
      events.remove(:test_event, handler1)
      
      expect(events.handlers_for(:test_event)).to eq([handler2])
    end

    it "removes all handlers for an event if no handler is specified" do
      events.on(:test_event) { |data| data }
      events.on(:test_event) { |data| data * 2 }
      
      events.remove(:test_event)
      
      expect(events.handlers_for(:test_event)).to be_empty
    end
  end

  describe "#clear" do
    it "removes all event handlers" do
      events.on(:event1) { |data| data }
      events.on(:event2) { |data| data }
      
      events.clear
      
      expect(events.events).to be_empty
    end
  end

  describe "#events" do
    it "returns all registered event names" do
      events.on(:event1) { |data| data }
      events.on(:event2) { |data| data }
      events.on(:event3) { |data| data }
      
      expect(events.events).to contain_exactly(:event1, :event2, :event3)
    end
  end
end