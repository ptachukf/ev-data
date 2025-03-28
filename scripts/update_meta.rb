#!/usr/bin/env ruby

require 'json'
require 'time'

# Read brands.json
brands_data = JSON.parse(File.read('data/v2/brands.json'))

# Count total vehicles
total_vehicles = 0
brands_data['brands'].each do |brand|
  models_path = "data/v2/#{brand['models_file']}"
  models_data = JSON.parse(File.read(models_path))
  total_vehicles += models_data['models'].size
end

# Update meta information
brands_data['meta'] = {
  'updated_at' => Time.now.utc.iso8601,
  'overall_count' => total_vehicles
}

# Save updated brands.json
File.write('data/v2/brands.json', JSON.pretty_generate(brands_data))

puts "Updated meta information:"
puts "- Total vehicles: #{total_vehicles}"
puts "- Updated at: #{brands_data['meta']['updated_at']}" 