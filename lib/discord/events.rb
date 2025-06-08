# frozen_string_literal: true

require "concurrent"

module Discord
  # Thread-safe event handling system for Discord events
  #
  # @example Registering an event handler
  #   events = Discord::Events.new
  #   events.on(:message_create) do |message|
  #     puts "New message: #{message[:content]}"
  #   end
  class Events
    def initialize
      @handlers = Concurrent::Hash.new { |h, k| h[k] = [] }
    end

    # Registers an event handler
    #
    # @param event [Symbol, String] The event name to listen for
    # @yield [*args] Block to be called when the event is emitted
    # @return [void]
    # @raise [ArgumentError] if no block is provided
    #
    # @example
    #   events.on(:ready) do |data|
    #     puts "Bot is ready!"
    #   end
    def on(event, &block)
      raise ArgumentError, "Block is required" unless block_given?

      event = event.to_sym
      @handlers[event] << block
    end

    # Emits an event to all registered handlers
    #
    # @param event [Symbol, String] The event name to emit
    # @param args [Array] Arguments to pass to the event handlers
    # @return [void]
    #
    # @note Each handler is executed in its own thread for performance
    # @note Errors in handlers are caught and logged to prevent crashes
    def emit(event, *args)
      event = event.to_sym
      return unless @handlers.key?(event)

      @handlers[event].each do |handler|
        Thread.new do
          handler.call(*args)
        rescue => e
          puts "Error in event handler for #{event}: #{e.message}"
          puts e.backtrace.join("\n")
        end
      end
    end

    # Removes event handler(s)
    #
    # @param event [Symbol, String] The event name
    # @param handler [Proc, nil] Specific handler to remove, or nil to remove all
    # @return [void]
    #
    # @example Remove a specific handler
    #   handler = proc { |data| puts data }
    #   events.on(:test, &handler)
    #   events.remove(:test, handler)
    #
    # @example Remove all handlers for an event
    #   events.remove(:test)
    def remove(event, handler = nil)
      event = event.to_sym

      if handler
        @handlers[event].delete(handler)
      else
        @handlers.delete(event)
      end
    end

    def clear
      @handlers.clear
    end

    def handlers_for(event)
      @handlers[event.to_sym].dup
    end

    def events
      @handlers.keys
    end
  end
end
