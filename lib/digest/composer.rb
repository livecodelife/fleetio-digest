# frozen_string_literal: true

module Digest
  class Composer
    def initialize(vehicles:, issues:, service_reminders:, start_date:, end_date:)
      @vehicles = vehicles
      @issues = issues
      @service_reminders = service_reminders
      @start_date = start_date
      @end_date = end_date
    end

    def compose
      {
        period: {
          start_date: @start_date.to_s,
          end_date: @end_date.to_s
        },
        vehicles: composed_vehicles,
        totals: calculate_totals
      }
    end

    private

    def composed_vehicles
      @vehicles.map do |vehicle|
        {
          vehicle: vehicle,
          issues: issues_for(vehicle[:id]),
          service_reminders: reminders_for(vehicle[:id])
        }
      end
    end

    def issues_for(vehicle_id)
      @issues.select { |i| i[:vehicle_id] == vehicle_id }
    end

    def reminders_for(vehicle_id)
      @service_reminders.select { |r| r[:vehicle_id] == vehicle_id }
    end

    def calculate_totals
      {
        vehicles: @vehicles.count,
        issues: @issues.count,
        open_issues: @issues.count { |i| i[:state]&.downcase != 'resolved' },
        overdue_issues: @issues.count { |i| i[:is_overdue] },
        resolved_issues: @issues.count { |i| i[:state]&.downcase == 'resolved' },
        service_reminders: @service_reminders.count
      }
    end
  end
end
