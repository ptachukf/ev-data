#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'optparse'

# Parse command line options
options = {
  input_dir: 'data/v2',
  output_file: 'data/ev-data.json',
  verbose: false,
  fix_duplicates: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"
  
  opts.on("-i", "--input DIRECTORY", "Input directory containing V2 format data (default: data/v2)") do |dir|
    options[:input_dir] = dir
  end
  
  opts.on("-o", "--output FILE", "Output file path for V1 format data (default: data/ev-data.json)") do |file|
    options[:output_file] = file
  end
  
  opts.on("-v", "--verbose", "Enable verbose output") do
    options[:verbose] = true
  end
  
  opts.on("-f", "--fix-duplicates", "Fix duplicate IDs by generating new UUIDs") do
    options[:fix_duplicates] = true
  end
  
  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

puts "Merging V2 data into V1 format (#{options[:output_file]})..."
puts "Input directory: #{options[:input_dir]}" if options[:verbose]

# Read the brands.json file
begin
  brands_file = "#{options[:input_dir]}/brands.json"
  puts "Reading brands file: #{brands_file}" if options[:verbose]
  brands_data = JSON.parse(File.read(brands_file))
  meta = brands_data['meta']
  brands = brands_data['brands']
rescue => e
  puts "Error reading brands.json: #{e.message}"
  exit 1
end

# Initialize the data array that will hold all vehicles
all_vehicles = []

# Keep track of data for validation
processed_brands = 0
processed_files = 0
skipped_files = 0

# Helper method to generate UUID
def generate_uuid
  SecureRandom.uuid
end

# Process each brand and its models
brands.each do |brand|
  models_file_path = "#{options[:input_dir]}/#{brand['models_file']}"
  puts "Processing brand: #{brand['name']} (#{models_file_path})" if options[:verbose]
  
  # Skip if the file doesn't exist
  unless File.exist?(models_file_path)
    puts "Warning: Model file not found: #{models_file_path}"
    skipped_files += 1
    next
  end
  
  # Read the models file
  begin
    models_data = JSON.parse(File.read(models_file_path))
    processed_files += 1
    
    # Ensure models array exists
    if models_data['models'].nil? || models_data['models'].empty?
      puts "Warning: No models found in #{models_file_path}"
      next
    end
    
    # Validate brand consistency
    if models_data['brand_id'] != brand['id']
      puts "Warning: Brand ID mismatch in #{models_file_path}. Expected: #{brand['id']}, Got: #{models_data['brand_id']}"
    end
    
    # Add each model to the all_vehicles array
    models_data['models'].each do |vehicle|
      # Ensure brand_id is set correctly
      vehicle['brand_id'] = brand['id'] if vehicle['brand_id'] != brand['id']
      
      # Ensure brand name is set correctly
      vehicle['brand'] = brand['name'] if vehicle['brand'] != brand['name']
      
      # Note: We do not add the "type": "bev" field as it's redundant
      
      all_vehicles << vehicle
    end
    
    processed_brands += 1
    
  rescue JSON::ParserError => e
    puts "Error parsing JSON in #{models_file_path}: #{e.message}"
    skipped_files += 1
  end
end

# Validate that overall_count matches the actual count
if meta['overall_count'] != all_vehicles.size
  puts "Warning: overall_count in meta (#{meta['overall_count']}) doesn't match actual vehicle count (#{all_vehicles.size})"
  # Update meta with correct count
  meta['overall_count'] = all_vehicles.size
end

# Check for duplicate IDs
vehicle_ids = all_vehicles.map { |v| v['id'] }
duplicate_ids = vehicle_ids.group_by { |id| id }.select { |id, occurrences| occurrences.size > 1 && !id.nil? }

if duplicate_ids.any?
  puts "\nWarning: Found #{duplicate_ids.size} duplicate vehicle IDs:"
  duplicate_ids.keys.take(5).each do |id|
    puts "  - #{id} (#{duplicate_ids[id].size} occurrences)"
  end
  puts "  - ... and #{duplicate_ids.size - 5} more" if duplicate_ids.size > 5
  
  if options[:fix_duplicates]
    puts "Fixing duplicate IDs..."
    require 'securerandom' # Required for UUID generation
    
    # Fix duplicate IDs by assigning new UUIDs
    all_vehicles.each_with_index do |vehicle, index|
      if vehicle['id'] && duplicate_ids.key?(vehicle['id'])
        # Keep the first occurrence, change all others
        occurrences = duplicate_ids[vehicle['id']]
        first_index = all_vehicles.index { |v| v['id'] == vehicle['id'] }
        
        if index != first_index
          old_id = vehicle['id']
          vehicle['id'] = SecureRandom.uuid
          puts "  Changed ID: #{old_id} → #{vehicle['id']}" if options[:verbose]
        end
      end
    end
  end
end

# Create the output structure (V1 format)
output = {
  'meta' => meta,
  'brands' => brands.map { |b| {'id' => b['id'], 'name' => b['name']} },
  'data' => all_vehicles
}

# Write to output file
begin
  FileUtils.mkdir_p(File.dirname(options[:output_file]))
  File.write(options[:output_file], JSON.pretty_generate(output))
rescue => e
  puts "Error writing to #{options[:output_file]}: #{e.message}"
  exit 1
end

# Print statistics
puts "\nMerge complete!"
puts "Created #{options[:output_file]}"
puts "\nStatistics:"
puts "Total brands: #{brands.size} (processed: #{processed_brands})"
puts "Total model files: #{processed_files} (skipped: #{skipped_files})"
puts "Total vehicles: #{all_vehicles.size}"
puts "Data file size: #{File.size(options[:output_file]) / 1024} KB" 