# frozen_string_literal: true

module Normalizers
  # Normalizes raw Fleetio service reminder API responses into canonical Ruby hashes
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
  class ServiceReminderNormalizer
    # Normalizes a single service reminder hash
    #
    # @param raw_reminder [Hash] Raw service reminder data from Fleetio API
    # @return [Hash] Normalized service reminder hash with symbol keys
    def self.normalize(raw_reminder)
      {
        id: raw_reminder['id']&.to_i,
        vehicle_id: raw_reminder['vehicle_id']&.to_i,
        name: raw_reminder['service_task_name']&.to_s,
        status: raw_reminder['service_reminder_status_name']&.to_s,
        due_date: raw_reminder['next_due_at']&.to_s,
        due_mileage: raw_reminder['next_due_meter_value']&.to_i,
        is_overdue: raw_reminder['service_reminder_status_name'] == 'overdue',
        created_at: raw_reminder['created_at']&.to_s,
        updated_at: raw_reminder['updated_at']&.to_s
      }
    end

    # Normalizes a collection of service reminder hashes
    #
    # @param raw_reminders [Array<Hash>] Array of raw service reminder data from Fleetio API
    # @return [Array<Hash>] Array of normalized service reminder hashes
    def self.normalize_collection(raw_reminders)
      return [] unless raw_reminders.is_a?(Array)
      
      raw_reminders.map { |reminder| normalize(reminder) }
    end
  end
end
