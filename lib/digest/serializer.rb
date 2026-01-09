# frozen_string_literal: true

module Digest
  class Serializer
    def initialize(digest)
      @digest = digest
    end

    def serialize
      lines = []
      
      lines << "Fleet Digest: #{@digest[:period][:start_date]} to #{@digest[:period][:end_date]}"
      lines << ""
      
      lines << "Totals:"
      lines << "- Vehicles: #{@digest[:totals][:vehicles]}"
      lines << "- Issues: #{@digest[:totals][:issues]} (Overdue: #{@digest[:totals][:overdue_issues]}) (Resolved: #{@digest[:totals][:resolved_issues]})"
      lines << "- Service Reminders: #{@digest[:totals][:service_reminders]}"
      lines << ""
      
      @digest[:vehicles].each do |entry|
        vehicle = entry[:vehicle]
        lines << "Vehicle: #{vehicle[:name]} (ID #{vehicle[:id]})"
        
        if entry[:issues].any?
          lines << "- Issues:"
          entry[:issues].each do |issue|
            status = issue[:is_overdue] ? " (overdue)" : ""
            status += " (resolved)" if issue[:is_resolved]
            text = issue[:summary] || issue[:description]
            lines << "  - #{text}#{status}"
          end
        end
        
        if entry[:service_reminders].any?
          lines << "- Service Reminders:"
          entry[:service_reminders].each do |reminder|
            due_str = reminder[:due_date] ? " due on #{Date.parse(reminder[:due_date]).strftime('%Y-%m-%d')}" : ""
            lines << "  - #{reminder[:name]}#{due_str}"
          end
        end
        
        lines << ""
      end
      
      lines.join("\n")
    end
  end
end
