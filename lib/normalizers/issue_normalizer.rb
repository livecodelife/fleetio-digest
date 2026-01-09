# frozen_string_literal: true

module Normalizers
  # Normalizes raw Fleetio issue API responses into canonical Ruby hashes
  # 
  # Responsibilities:
  # - Field selection
  # - Type coercion
  # - Key renaming
  # - Data reduction
  #
  # Rules:
  # - Convert all keys to symbols
  # - Strip unused fields aggressively
  # - Never mutate the original hash
  class IssueNormalizer
    # Normalizes a single issue hash
    #
    # @param raw_issue [Hash] Raw issue data from Fleetio API
    # @return [Hash] Normalized issue hash with symbol keys
    def self.normalize(raw_issue)
      {
        id: raw_issue['id']&.to_i,
        vehicle_id: raw_issue['vehicle_id']&.to_i,
        description: raw_issue['description']&.to_s,
        summary: raw_issue['summary']&.to_s,
        state: raw_issue['state']&.to_s,
        due_date: raw_issue['due_date']&.to_s,
        is_overdue: raw_issue['overdue'] || false,
        reported_at: raw_issue['reported_at']&.to_s,
        created_at: raw_issue['created_at']&.to_s,
        updated_at: raw_issue['updated_at']&.to_s,
        resolved_at: raw_issue['resolved_at']&.to_s
      }
    end

    # Normalizes a collection of issue hashes
    #
    # @param raw_issues [Array<Hash>] Array of raw issue data from Fleetio API
    # @return [Array<Hash>] Array of normalized issue hashes
    def self.normalize_collection(raw_issues)
      return [] unless raw_issues.is_a?(Array)
      
      raw_issues.map { |issue| normalize(issue) }
    end
  end
end
