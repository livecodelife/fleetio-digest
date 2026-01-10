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
      @prev_response_id = nil
      @prompt_history = []
    end

    def complete(prompt)
      @prompt_history << {role: "user", content: prompt}
      @connection.post('/v1/responses') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          model: @model,
          instructions: "You are a fleet operations assistant. Your job is to help recommend actions to improve fleet operations and management.",
          input: @prompt_history,
          stream: true,
          previous_response_id: @prev_response_id,
          reasoning: {effort: "medium"}
        }.to_json

        @prompt_history << {role: "assistant", content: handle_response(req)}
      end
    end

    private

    def setup_connection
      Faraday.new(url: @base_url) do |f|
        f.options.timeout = 1000
        f.request :retry, max: 3, interval: 0.5
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(req)
      response_text = ""
      cleared = false
      req.options.on_data = Proc.new do |chunk, overall_received_bytes|
        # SSE events begin with "data: "
        lines = chunk.split("\n")
        lines.each do |line|
          next if line.strip.empty?

          if line.start_with?("data: ")
            json_str = line.sub("data: ", "").strip

            begin
              event = JSON.parse(json_str)
              if event["type"] == "response.in_progress"
                puts "Please wait..."
              end

              if event["type"] == "response.completed"
                @prev_response_id = event["response"]["id"]
              end

              if event["type"] == "response.reasoning_text.delta"
                print event["delta"]
              end

              if event["type"] == "response.reasoning_text.done"
                count = event["text"].split("\n").size * 2

                count.times do
                  print "\e[1A\e[2K"
                end
                print "\r"
              end

              if event["type"] == "response.output_text.delta"
                response_text += event["delta"]
                print event["delta"]
                STDOUT.flush
              end
            rescue JSON::ParserError
              # ignore parse errors (e.g., partial JSON)
            end
          end
        end
      end
      response_text
    end
  end
end
