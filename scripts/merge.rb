require 'multi_json'

if ARGV.length != 3
  puts "Usage: ruby merge.rb <file1> <file2> <output>"
  exit 1
end

file1 = ARGV[0]
file2 = ARGV[1]
output = ARGV[2]

# Load JSON files
data1 = MultiJson.load(File.read(file1))
data2 = MultiJson.load(File.read(file2))

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

merged_meta = data1.fetch('meta', {}).merge(data2.fetch('meta', {}))

# Create the final merged JSON structure
merged_result = {
  'data' => merged_data.values,
  'brands' => merged_brands.values,
  'meta' => merged_meta
}

# Save merged data to a new JSON file
File.write(output, MultiJson.dump(merged_result, pretty: true))
