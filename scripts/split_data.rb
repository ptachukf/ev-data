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

# Save brands.json
File.write('data/v2/brands.json', JSON.pretty_generate({
  'meta' => data['meta'],
  'brands' => brands
}))

# Create models directory
FileUtils.mkdir_p('data/v2/models')

# Group vehicles by brand_id
vehicles_by_brand = data['data'].group_by { |vehicle| vehicle['brand_id'] }

# Save each brand's vehicles to a separate file
brands.each do |brand|
  brand_vehicles = vehicles_by_brand[brand['id']] || []
  
  # Create the models file for this brand
  File.write("data/v2/#{brand['models_file']}", JSON.pretty_generate({
    'brand_id' => brand['id'],
    'brand_name' => brand['name'],
    'models' => brand_vehicles
  }))
end

puts "Data split complete!"
puts "Created data/v2/brands.json and individual model files in data/v2/models/" 