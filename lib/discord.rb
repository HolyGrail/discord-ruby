# frozen_string_literal: true

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
end
