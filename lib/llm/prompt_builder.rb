# frozen_string_literal: true

module LLM
  class PromptBuilder
    def self.build(digest_text)
      <<~PROMPT
        Summarize the following fleet activity from the last week.

        Focus on:
        - Critical or overdue issues
        - Vehicles needing immediate attention
        - Overall fleet trends

        Provide specific recommendations for fleet management based on the data.

        Do not relist the data. Just provide recommendations with a reasoning about your recommendations.

        Do not invent information. Base your summary only on the provided data.

        ---

        #{digest_text}
      PROMPT
    end
  end
end
