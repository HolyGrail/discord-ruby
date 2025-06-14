# frozen_string_literal: true

require "logger"
require_relative "discord/version"
require_relative "discord/client"
require_relative "discord/gateway"
require_relative "discord/http"
require_relative "discord/events"

module Discord
  class Error < StandardError; end

  class AuthenticationError < Error; end

  class APIError < Error; end

  class GatewayError < Error; end

  # Default logger for Discord gem
  # @return [Logger] The logger instance
  def self.logger
    @logger ||= Logger.new($stdout, level: Logger::WARN)
  end

  # Set a custom logger
  # @param logger [Logger] The logger to use
  def self.logger=(logger)
    @logger = logger
  end
end
