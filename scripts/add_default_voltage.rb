# frozen_string_literal: true

require 'contentful/management'
require 'dotenv'

# Load environment variables from .env file
Dotenv.load('.env')

PAGE_SIZE = 100

def client
  @client ||= ::Contentful::Management::Client.new(
    ENV['CONTENTFUL_MANAGEMENT_TOKEN']
  )
end

def environment
  @environment ||= client.environments(ENV['CONTENTFUL_SPACE_ID']).find(ENV['CONTENTFUL_ENVIRONMENT_ID'] || 'master')
end

def update_charging_voltage(entry)
  original_value = entry.fields[:charging_voltage]
  if original_value.nil? || original_value.empty?
    begin
      entry.charging_voltage = 400
      entry.save
      entry.publish
      puts "Successfully updated and published entry #{entry.id}: Set charging_voltage to 400"
    rescue Contentful::Management::Conflict
      puts "Conflict occurred for entry #{entry.id}. Retrying..."
      entry.reload
      retry
    rescue StandardError => e
      puts "Error updating entry #{entry.id}: #{e.message}"
    end
  else
    puts "Entry #{entry.id} already has a charging_voltage value: #{original_value}. Skipping."
  end
end

def process_entries
  fetch_entries do |entry|
    update_charging_voltage(entry)
  end
end

def fetch_entries
  current_skip = 0
  loop do
    current_page = environment.entries.all(content_type: 'vehicleModelVariant', limit: PAGE_SIZE, skip: current_skip, order: '-sys.updatedAt')
    break if current_page.empty?
    current_page.each do |entry|
      yield entry if block_given?
    end
    current_skip += current_page.size
  end
end

# Main execution
begin
  puts "Starting data cleanup..."
  process_entries
  puts "Data cleanup completed successfully."
rescue StandardError => e
  puts "An error occurred: #{e.message}"
  puts e.backtrace.join("\n")
end