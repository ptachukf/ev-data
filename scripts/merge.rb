require 'multi_json'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby script.rb [options]"

  opts.on("-f1", "--file1 FILE1", "Path to the first JSON file") do |file1|
    options[:file1] = file1
  end

  opts.on("-f2", "--file2 FILE2", "Path to the second JSON file") do |file2|
    options[:file2] = file2
  end

  opts.on("-o", "--output FILE", "Path to save the merged JSON file") do |output|
    options[:output] = output
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:file1].nil? || options[:file2].nil?
  puts "Please provide both file paths using the -f1 and -f2 options."
  exit 1
end

if options[:output].nil?
  puts "Please provide the output file path using the -o option."
  exit 1
end

# Load JSON files
data1 = MultiJson.load(File.read(options[:file1]))
data2 = MultiJson.load(File.read(options[:file2]))

# Merge 'data' arrays, avoiding duplicates
merged_data = data1['data'].map { |item| [item['id'], item] }.to_h
data2['data'].each do |item|
  if merged_data[item['id']].nil?
    merged_data[item['id']] = item
  else
    # Merge fields if the item exists
    item.each do |key, value|
      merged_data[item['id']][key] ||= value
    end
  end
end

# Merge 'brands' and 'meta' fields, avoiding duplicates
merged_brands = data1.fetch('brands', []).map { |item| [item['id'], item] }.to_h
data2.fetch('brands', []).each do |item|
  merged_brands[item['id']] ||= item
end

merged_meta = data1.fetch('meta', []).map { |item| [item['key'], item] }.to_h
data2.fetch('meta', []).each do |item|
  merged_meta[item['key']] ||= item
end

# Create the final merged JSON structure
merged_result = {
  'data' => merged_data.values,
  'brands' => merged_brands.values,
  'meta' => merged_meta.values
}

# Save merged data to a new JSON file
File.write(options[:output], MultiJson.dump(merged_result, pretty: true))
