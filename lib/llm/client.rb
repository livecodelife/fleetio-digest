# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'
require 'json'

module LLM
  class Client
    class Error < StandardError; end

    def initialize(base_url:, model:)
      @base_url = base_url
      @model = model
      @connection = setup_connection
    end

    def complete(prompt)
      response = @connection.post('/v1/responses') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          model: @model,
          instructions: "You are a fleet operations assistant.",
          input: prompt
        }.to_json
      end

      handle_response(response)
    rescue Faraday::Error => e
      raise Error, "LLM Request failed: #{e.message}"
    end

    private

    def setup_connection
      Faraday.new(url: @base_url) do |f|
        f.options.timeout = 1000
        f.request :retry, max: 3, interval: 0.5
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      unless response.success?
        raise Error, "LLM API Error: #{response.status} - #{response.body}"
      end

      body = JSON.parse(response.body)
      output = body.dig("output")
      content = output.find { |o| o["status"] == "completed" }.dig("content", 0, "text")
      
      unless content
        raise Error, "Invalid LLM response format: missing output/content/text"
      end

      content
    rescue JSON::ParserError
      raise Error, "Invalid JSON response from LLM"
    end
  end
end
