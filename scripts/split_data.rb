#!/usr/bin/env ruby

require 'json'
require 'fileutils'

# Read the original data file
data = JSON.parse(File.read('data/ev-data.json'))

# Create v2 directory if it doesn't exist
FileUtils.mkdir_p('data/v2')

# Extract and save brands with references to their model files
brands = data['brands'].map do |brand|
  snake_case_name = brand['name'].downcase.gsub(/[^a-z0-9]+/, '_')
  {
    'id' => brand['id'],
    'name' => brand['name'],
    'models_file' => "models/#{snake_case_name}.json"
  }
end

# Process all vehicles first to get the correct count
vehicles_by_brand = data['data'].group_by { |vehicle| vehicle['brand_id'] }
total_vehicles = 0

# Helper function to create a unique key for a vehicle
def vehicle_key(vehicle)
  [
    vehicle['model'],
    vehicle['variant'],
    vehicle['usable_battery_size'],
    vehicle['ac_charger'] ? vehicle['ac_charger']['max_power'] : nil,
    vehicle['dc_charger'] ? vehicle['dc_charger']['max_power'] : nil
  ]
end

# Process all brands to get total count
processed_vehicles = {}
brands.each do |brand|
  brand_vehicles = vehicles_by_brand[brand['id']] || []
  
  # Remove duplicates while preserving vehicles with different specifications
  unique_vehicles = {}
  brand_vehicles.each do |vehicle|
    key = vehicle_key(vehicle)
    # If we have a duplicate, keep the one with more information
    if !unique_vehicles[key] || 
       (vehicle['dc_charger'] && !unique_vehicles[key]['dc_charger']) ||
       (vehicle['ac_charger'] && !unique_vehicles[key]['ac_charger']) ||
       (vehicle['energy_consumption'] && !unique_vehicles[key]['energy_consumption'])
      # Simply store the vehicle without modifying power points
      unique_vehicles[key] = vehicle.dup
    end
  end
  
  processed_vehicles[brand['id']] = unique_vehicles.values.sort_by { |v| [v['model'].to_s, v['variant'].to_s] }
  total_vehicles += unique_vehicles.size
end

# Save brands.json with updated meta information
meta = data['meta'].dup
meta['overall_count'] = total_vehicles
File.write('data/v2/brands.json', JSON.pretty_generate({
  'meta' => meta,
  'brands' => brands
}))

# Create models directory
FileUtils.mkdir_p('data/v2/models')

# Save each brand's vehicles to a separate file
brands.each do |brand|
  # Create the models file for this brand
  File.write("data/v2/#{brand['models_file']}", JSON.pretty_generate({
    'brand_id' => brand['id'],
    'brand_name' => brand['name'],
    'models' => processed_vehicles[brand['id']]
  }))
end

# Print statistics
v1_count = data['data'].length
v2_count = total_vehicles

puts "Data split complete!"
puts "Created data/v2/brands.json and individual model files in data/v2/models/"
puts "\nStatistics:"
puts "V1 total models: #{v1_count}"
puts "V2 total models: #{v2_count}"
puts "Difference: #{v1_count - v2_count} models"
if v1_count != v2_count
  puts "\nModel counts by brand:"
  brands.each do |brand|
    v1_brand_count = vehicles_by_brand[brand['id']].length
    v2_brand_count = processed_vehicles[brand['id']].length
    if v1_brand_count != v2_brand_count
      puts "#{brand['name']}: #{v1_brand_count} -> #{v2_brand_count} (#{v1_brand_count - v2_brand_count} removed)"
    end
  end
end 