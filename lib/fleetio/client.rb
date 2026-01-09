# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'
require 'json'

module Fleetio
  # HTTP client for Fleetio API
  # Handles authentication, retry logic, and JSON parsing
  class Client
    class Error < StandardError; end
    class AuthenticationError < Error; end
    class NotFoundError < Error; end
    class RateLimitError < Error; end

    attr_reader :connection

    def initialize(api_key:, account_token:, base_url:)
      @api_key = api_key
      @account_token = account_token
      @base_url = base_url

      validate_config!
      @connection = build_connection
    end

    # Perform a GET request
    # @param path [String] API endpoint path
    # @param params [Hash] Query parameters
    # @return [Hash] Parsed JSON response
    def get(path, params = {})
      response = connection.get(path, params)
      handle_response(response)
    rescue Faraday::Error => e
      raise Error, "Request failed: #{e.message}"
    end

    private

    def validate_config!
      raise Error, "API key is required" if @api_key.nil? || @api_key.empty?
      raise Error, "Account token is required" if @account_token.nil? || @account_token.empty?
      raise Error, "Base URL is required" if @base_url.nil? || @base_url.empty?
    end

    def build_connection
      Faraday.new(url: @base_url) do |faraday|
        # Request middleware
        faraday.request :json
        faraday.request :retry, {
          max: 3,
          interval: 0.5,
          backoff_factor: 2,
          retry_statuses: [429, 500, 502, 503, 504],
          methods: [:get]
        }

        # Response middleware
        faraday.response :json, content_type: /\bjson$/
        faraday.response :raise_error

        # Headers
        faraday.headers['Authorization'] = @api_key
        faraday.headers['Account-Token'] = @account_token
        faraday.headers['Accept'] = 'application/json'

        # Adapter
        faraday.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 401, 403
        raise AuthenticationError, "Authentication failed: #{response.status}"
      when 404
        raise NotFoundError, "Resource not found"
      when 429
        raise RateLimitError, "Rate limit exceeded"
      else
        raise Error, "Request failed with status #{response.status}"
      end
    end
  end
end
