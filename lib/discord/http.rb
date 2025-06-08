# frozen_string_literal: true

require "rest-client"
require "json"

module Discord
  # HTTP client for Discord REST API interactions
  #
  # @api private
  class HTTP
    BASE_URL = "https://discord.com/api/v10"
    USER_AGENT = "DiscordBot (https://github.com/HolyGrail/discord-ruby, #{Discord::VERSION})"

    # Creates a new HTTP client
    #
    # @param token [String] Discord bot token
    def initialize(token)
      @token = token
      @headers = {
        "Authorization" => "Bot #{token}",
        "User-Agent" => USER_AGENT,
        "Content-Type" => "application/json"
      }
    end

    # Performs a GET request
    #
    # @param endpoint [String] API endpoint path
    # @param params [Hash] Query parameters
    # @return [Hash, nil] Parsed response body
    # @raise [Discord::APIError] on API errors
    def get(endpoint, params = {})
      request(:get, endpoint, params: params)
    end

    # Performs a POST request
    #
    # @param endpoint [String] API endpoint path
    # @param payload [Hash] Request body
    # @return [Hash, nil] Parsed response body
    # @raise [Discord::APIError] on API errors
    def post(endpoint, payload = {})
      request(:post, endpoint, payload: payload)
    end

    def patch(endpoint, payload = {})
      request(:patch, endpoint, payload: payload)
    end

    def put(endpoint, payload = {})
      request(:put, endpoint, payload: payload)
    end

    def delete(endpoint)
      request(:delete, endpoint)
    end

    private

    def request(method, endpoint, params: {}, payload: nil)
      url = "#{BASE_URL}#{endpoint}"

      options = {
        method: method,
        url: url,
        headers: @headers
      }

      options[:payload] = payload.to_json if payload && %i[post patch put].include?(method)

      # Add query parameters for GET requests
      unless params.empty?
        query_string = URI.encode_www_form(params)
        url += "?#{query_string}"
        options[:url] = url
      end

      response = RestClient::Request.execute(options)
      parse_response(response)
    rescue RestClient::BadRequest => e
      handle_error(e)
    rescue RestClient::Unauthorized
      raise AuthenticationError, "Invalid token"
    rescue RestClient::Forbidden => e
      handle_error(e)
    rescue RestClient::NotFound => e
      handle_error(e)
    rescue RestClient::TooManyRequests => e
      handle_rate_limit(e)
    rescue RestClient::Exception => e
      handle_error(e)
    end

    def parse_response(response)
      return nil if response.body.empty?
      JSON.parse(response.body, symbolize_names: true)
    rescue JSON::ParserError
      response.body
    end

    def handle_error(error)
      if error.response&.body
        begin
          error_data = JSON.parse(error.response.body, symbolize_names: true)
          message = error_data[:message] || error.message
          code = error_data[:code]
          raise APIError, "Discord API Error (#{code}): #{message}"
        rescue JSON::ParserError
          raise APIError, "Discord API Error: #{error.message}"
        end
      else
        raise APIError, "Discord API Error: #{error.message}"
      end
    end

    def handle_rate_limit(error)
      if error.response && error.response.headers[:retry_after]
        retry_after = error.response.headers[:retry_after].to_f
        raise APIError, "Rate limited. Retry after #{retry_after} seconds"
      else
        handle_error(error)
      end
    end
  end
end
