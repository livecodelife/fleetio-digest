# frozen_string_literal: true

require 'date'
require_relative 'client'

module Fleetio
  # Fleetio API endpoint methods
  # Each method corresponds to a specific Fleetio API endpoint
  class Endpoints
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # Fetch vehicles updated within a date range
    # @param start_date [String] Date string (DD-MM-YYYY)
    # @param end_date [String] Date string (DD-MM-YYYY)
    # @return [Array<Hash>] Array of vehicle hashes
    def fetch_vehicles(start_date:, end_date:)
      params = build_date_params(start_date, end_date)
      response = client.get('vehicles', params)
      next_cursor = response['next_cursor']
      records = extract_records(response)
      while next_cursor
        response = client.get('vehicles', params.merge('start_cursor' => next_cursor))
        next_cursor = response['next_cursor']
        records += extract_records(response)
      end
      records
    end

    # Fetch issues created or updated within a date range
    # Note: Issues endpoint doesn't support date filtering, so we fetch all and filter in code
    # @param start_date [String] Date string (DD-MM-YYYY)
    # @param end_date [String] Date string (DD-MM-YYYY)
    # @return [Array<Hash>] Array of issue hashes
    def fetch_issues(start_date:, end_date:)
      response = client.get('issues')
      filter_by_date_range(response, start_date, end_date)
    end

    # Fetch service reminders within a date range
    # Note: Service reminders endpoint doesn't support date filtering, so we fetch all and filter in code
    # @param start_date [String] Date string (DD-MM-YYYY)
    # @param end_date [String] Date string (DD-MM-YYYY)
    # @return [Array<Hash>] Array of service reminder hashes
    def fetch_service_reminders(start_date:, end_date:)
      response = client.get('service_reminders')
      filter_by_date_range(response, start_date, end_date)
    end

    private

    # Build query parameters for date filtering (vehicles only)
    # Uses updated_at filter for Fleetio API
    # Converts DD-MM-YYYY to YYYY-MM-DD format for API
    def build_date_params(start_date, end_date)
      # Parse DD-MM-YYYY and convert to YYYY-MM-DD ISO format
      start_iso = start_date.strftime('%Y-%m-%d')
      # Add 1 day to end date to include records updated on the end date (using lt filter)
      end_iso = (end_date + 1).strftime('%Y-%m-%d')

      {
        'filter[updated_at][gte]' => start_iso,
        'per_page' => 100
      }
    end

    # Extract records from Fleetio paginated response
    # @param response [Hash] API response hash
    # @return [Array<Hash>] Array of records
    def extract_records(response)
      return [] unless response.is_a?(Hash)
      response['records'] || []
    end

    # Filter records by date range based on updated_at field
    # @param records [Array<Hash>] Array of record hashes
    # @param start_date [String] Date string (DD-MM-YYYY)
    # @param end_date [String] Date string (DD-MM-YYYY)
    # @return [Array<Hash>] Filtered array of records
    def filter_by_date_range(records, start_date, end_date)
      return [] if records.empty?

      records.select do |record|
        next false unless record['updated_at']

        updated_at = DateTime.parse(record['updated_at']).to_date
        updated_at >= start_date && updated_at <= end_date
      end
    end
  end
end
