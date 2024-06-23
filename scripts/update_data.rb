# frozen_string_literal: true

require 'shortuuid'
require 'contentful'
require 'multi_json'
require 'pry'
require 'dotenv'

# Check if .env file is available
unless File.exist?('.env')
  puts "Error: .env file not found. Please create a .env file with the required configuration."
  exit 1
end

Dotenv.load('.env')

FILE_NAME = '../data/contentful-export.json'
PAGE_SIZE = 100

def load_from_contentful
  entries = fetch_entries
  brands = entries.map do |v|
    model = v.model
    brand = v.model&.brand if model
    id = deterministic_uuid(brand.id) if brand
    name = brand&.name if brand
    { id: id, name: name } 
  end.compact.uniq.sort_by { |c| c[:name] }
  vehicles = entries.map { |entry| to_model(entry) }.sort_by { |v| [v[:brand], v[:model], v[:variant]] }

  hash = {
    data: vehicles,
    brands: brands,
    meta: {
      updated_at: Time.now.utc.iso8601,
      overall_count: vehicles.size
    }
  }

  File.write(FILE_NAME, MultiJson.dump(hash, pretty: true))
end

def fetch_entries
  current_skip = 0
  entries_per_page = []
  loop do
    current_page = client.entries(content_type: 'vehicleModelVariant', include: 2, skip: current_skip, order: "-sys.updatedAt")
    entries_per_page << current_page.to_a
    current_page.length.zero? ? break : current_skip += PAGE_SIZE
  end

  entries_per_page.flatten
end

def client
  @client ||= ::Contentful::Client.new(
    space: ENV['CONTENTFUL_SPACE_ID'],
    access_token: ENV['CONTENTFUL_ACCESS_TOKEN'],
    raise_for_empty_fields: false,
    dynamic_entries:        :auto
  )
end

def to_model(entry)
  {
    id: deterministic_uuid(entry.id),
    brand: entry.model.brand.name,
    vehicle_type: entry.model.vehicle_type,
    type: entry.model.ev_type,
    brand_id: deterministic_uuid(entry.model.brand.id),
    model: entry.model.name,
    release_year: entry.release_year,
    variant: entry.variant.to_s,
    usable_battery_size: format_float(entry.battery_size),
    ac_charger: ac_charger(entry),
    dc_charger: dc_charger(entry),
    energy_consumption: {
      average_consumption: format_float(entry.average_consumption)
    },
    charging_voltage: entry.charging_voltage.to_i
  }
end

def ac_charger(entry)
  {
    usable_phases: entry.ac_phases,
    ports: entry.ac_ports || [],
    max_power: format_float(entry.max_ac_power),
    power_per_charging_point: power_per_charging_point(entry)
  }
end

def dc_charger(entry)
  ports = entry.dc_ports || []
  return if ports.empty?

  curve = dc_charging_curve(entry)
  max_power = entry.max_dc_power
  {
    ports: ports,
    max_power: format_float(curve ? curve.max_by { |v| v[:power] }[:power] : max_power),
    charging_curve: dc_charging_curve(entry),
    is_default_charging_curve: !entry.dc_charging_curve
  }
end

def dc_charging_curve(entry)
  unless entry.dc_charging_curve
    return nil unless entry.max_dc_power

    max_dc_power = entry.max_dc_power.to_f
    max_ac_power = entry.max_ac_power.to_f
    return default_charging_curve(max_dc_power, max_ac_power)
  end

  entry.dc_charging_curve.map do |item|
    vals = item.split(',')
    { percentage: Integer(vals[0]), power: format_float(Float(vals[1])) }
  end
end

def default_charging_curve(max_dc_power, max_ac_power)
  [
    { percentage: 0, power: format_float(max_dc_power * 0.95) },
    { percentage: 75, power: format_float(max_dc_power) },
    { percentage: 100, power: format_float(max_ac_power) }
  ]
end

def power_per_charging_point(entry)
  max_power = entry.max_ac_power.to_f
  max_phases = entry.ac_phases
  {
    2.0 => format_float([max_power, 2.0].min),
    2.3 => format_float([max_power, 2.3].min),
    3.7 => format_float([max_power, 3.7].min),
    7.4 => format_float([max_power, 7.4].min),
    11 => format_float([max_power, max_phases * 3.7].min),
    16 => format_float([max_power, max_phases * 5.4].min),
    22 => format_float([max_power, max_phases * 7.4].min),
    43 => format_float(max_power > 22 ? max_power : [max_power, max_phases * 7.4].min)
  }
end

def format_float(value)
  "%.1f" % value.to_f
end

def deterministic_uuid(id)
  ShortUUID.expand(id)
end

load_from_contentful
puts "Saved to #{FILE_NAME}"