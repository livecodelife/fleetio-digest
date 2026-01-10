#!/usr/bin/env ruby
# frozen_string_literal: true

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'dotenv/load'
require 'date'
require 'active_support/core_ext/numeric/time'
require 'json'

require 'fleetio/client'
require 'fleetio/endpoints'
require 'normalizers/vehicle_normalizer'
require 'normalizers/issue_normalizer'
require 'normalizers/service_reminder_normalizer'
require 'digest/composer'
require 'digest/serializer'
require 'llm/client'
require 'llm/prompt_builder'

# Validate environment variables
def validate_environment!
  required_vars = %w[
    FLEETIO_API_KEY
    FLEETIO_ACCOUNT_TOKEN
    FLEETIO_BASE_URL
    LM_STUDIO_BASE_URL
    LM_STUDIO_MODEL
  ]

  missing_vars = required_vars.select { |var| ENV[var].nil? || ENV[var].empty? }

  return if missing_vars.empty?

  puts "❌ Missing required environment variables:"
  missing_vars.each { |var| puts "  - #{var}" }
  exit 1
end

# Calculate date range for last week
def last_week_range
  today = Date.today
  end_date = today
  start_date = today - 7.days

  {
    start_date: start_date,
    end_date: end_date
  }
end

# Format and print results
def print_results(resource_type, data)
  puts "\n" + "=" * 80
  puts "#{resource_type.upcase}"
  puts "=" * 80

  if data.empty?
    puts "No #{resource_type} found for this period."
    return
  end

  puts "Found #{data.count} #{resource_type}:\n\n"
  puts JSON.pretty_generate(data)
end

# Main execution
def main
  puts "🚀 Fleet Digest Pipeline - Data Fetching Phase"
  puts "=" * 80

  # Step 1: Validate environment
  puts "\n📋 Step 1: Validating environment..."
  validate_environment!
  puts "✅ Environment validated"

  # Step 2: Calculate date range
  puts "\n📅 Step 2: Calculating date range..."
  range = last_week_range
  puts "✅ Range: #{range[:start_date]} to #{range[:end_date]}"

  # Step 3: Initialize Fleetio client
  puts "\n🔌 Step 3: Initializing Fleetio client..."
  client = Fleetio::Client.new(
    api_key: ENV['FLEETIO_API_KEY'],
    account_token: ENV['FLEETIO_ACCOUNT_TOKEN'],
    base_url: ENV['FLEETIO_BASE_URL']
  )
  endpoints = Fleetio::Endpoints.new(client)
  puts "✅ Client initialized"

  # Step 4: Fetch vehicles
  puts "\n🚗 Step 4: Fetching vehicles..."
  vehicles = endpoints.fetch_vehicles(
    start_date: range[:start_date],
    end_date: range[:end_date]
  )
  puts "✅ Retrieved #{vehicles.count} vehicles"

  # Step 5: Normalize vehicles
  puts "\n🔄 Step 5: Normalizing vehicles..."
  normalized_vehicles = Normalizers::VehicleNormalizer.normalize_collection(vehicles)

  # Step 6: Fetch issues
  puts "\n🔧 Step 6: Fetching issues..."
  issues = endpoints.fetch_issues(
    start_date: range[:start_date],
    end_date: range[:end_date]
  )
  puts "✅ Retrieved #{issues.count} issues"

  # Step 7: Normalize issues
  puts "\n🔄 Step 7: Normalizing issues..."
  normalized_issues = Normalizers::IssueNormalizer.normalize_collection(issues)

  # Step 8: Fetch service reminders
  puts "\n⚙️  Step 8: Fetching service reminders..."
  service_reminders = endpoints.fetch_service_reminders(
    start_date: range[:start_date],
    end_date: range[:end_date]
  )
  puts "✅ Retrieved #{service_reminders.count} service reminders"

  # Step 9: Normalize service reminders
  puts "\n🔄 Step 9: Normalizing service reminders..."
  normalized_service_reminders = Normalizers::ServiceReminderNormalizer.normalize_collection(service_reminders)

  # Step 10: Compose Digest
  puts "\n📦 Step 10: Composing digest..."
  composer = Digest::Composer.new(
    vehicles: normalized_vehicles,
    issues: normalized_issues,
    service_reminders: normalized_service_reminders,
    start_date: range[:start_date],
    end_date: range[:end_date]
  )
  digest = composer.compose
  puts "✅ Digest composed"

  # Step 11: Serialize Digest
  puts "\n📝 Step 11: Serializing digest..."
  serializer = Digest::Serializer.new(digest)
  serialized_output = serializer.serialize
  puts "✅ Digest serialized"

  # Step 12: Generate Summary
  puts "\n🤖 Step 12: Generating LLM Summary..."

  prompt = LLM::PromptBuilder.build(serialized_output)

  llm_client = LLM::Client.new(
    base_url: ARGV[1] || ENV['LM_STUDIO_BASE_URL'],
    model: ARGV[0] || ENV['LM_STUDIO_MODEL']
  )

  puts "✅ Summary generated"

  # Step 13: Display Results
  puts "\n" + "=" * 80
  puts "FLEET WEEKLY DIGEST"
  puts "This week you have:"
  puts "- #{digest[:totals][:open_issues]} open issues"
  puts "- #{digest[:totals][:overdue_issues]} overdue issues"
  puts "- #{digest[:totals][:resolved_issues]} resolved issues"
  puts "- #{digest[:totals][:service_reminders]} service reminders"
  puts "=" * 80
  llm_client.complete(prompt)
  puts "=" * 80
  print "\n Do you have any questions? > "

  prompt = gets.chomp

  while prompt != "exit"
    llm_client.complete(prompt)
    print "\n Do you have any other questions? > "
    prompt = gets.chomp
  end

rescue Fleetio::Client::Error => e
  puts "\n❌ Fleetio API Error: #{e.message}"
  exit 1
rescue StandardError => e
  puts "\n❌ Unexpected Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

# Run the script
main if __FILE__ == $PROGRAM_NAME
