# frozen_string_literal: true

module Normalizers
  # Normalizes raw Fleetio vehicle API responses into canonical Ruby hashes
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
  class VehicleNormalizer
    # Normalizes a single vehicle hash
    #
    # @param raw_vehicle [Hash] Raw vehicle data from Fleetio API
    # @return [Hash] Normalized vehicle hash with symbol keys
    def self.normalize(raw_vehicle)
      {
        id: raw_vehicle['id']&.to_i,
        name: raw_vehicle['name']&.to_s,
        vin: raw_vehicle['vin']&.to_s,
        status: raw_vehicle['vehicle_status_name']&.to_s,
        group_name: raw_vehicle['group_name']&.to_s,
        make: raw_vehicle['make']&.to_s,
        model: raw_vehicle['model']&.to_s,
        year: raw_vehicle['year']&.to_i,
        vehicle_type_name: raw_vehicle['vehicle_type_name']&.to_s,
        primary_meter_value: raw_vehicle['primary_meter_value']&.to_i || 0,
        issues_count: raw_vehicle['issues_count']&.to_i || 0,
        service_reminders_count: raw_vehicle['service_reminders_count']&.to_i || 0,
        updated_at: raw_vehicle['updated_at']&.to_s
      }
    end

    # Normalizes a collection of vehicle hashes
    #
    # @param raw_vehicles [Array<Hash>] Array of raw vehicle data from Fleetio API
    # @return [Array<Hash>] Array of normalized vehicle hashes
    def self.normalize_collection(raw_vehicles)
      return [] unless raw_vehicles.is_a?(Array)
      
      raw_vehicles.map { |vehicle| normalize(vehicle) }
    end
  end
end
