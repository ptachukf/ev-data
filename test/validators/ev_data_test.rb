require_relative '../test_helper'

class EVDataTest < Minitest::Test
  class << self
    include Validators::ClassMethods
  end

  def setup
    @json_data = JSON.parse(File.read('data/ev-data.json'))
  end

  def assert_charging_ports(vehicle)
    # AC charger validation
    if vehicle["ac_charger"]
      assert vehicle["ac_charger"]["ports"].is_a?(Array), 
        "AC ports must be an array for #{vehicle['brand']} #{vehicle['model']}"
      # No validation for empty AC ports - they're allowed
    end

    # DC charger must have ports if it exists and isn't null
    if vehicle["dc_charger"] && !vehicle["dc_charger"].nil?
      assert vehicle["dc_charger"]["ports"].is_a?(Array), 
        "DC ports must be an array for #{vehicle['brand']} #{vehicle['model']}"
      assert !vehicle["dc_charger"]["ports"].empty?, 
        "DC ports cannot be empty when DC charging exists for #{vehicle['brand']} #{vehicle['model']}"
    end
  end

  def test_charging_validation
    valid_data = {
      "ac_charger" => {
        "ports" => [],  # Empty ports are now valid
        "max_power" => 11.0,
        "usable_phases" => 3
      },
      "dc_charger" => {
        "ports" => ["ccs"],
        "max_power" => 150.0
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(valid_data)
    assert_empty errors, "Expected no validation errors for valid charging details"
  end

  def test_invalid_ac_ports_not_array
    invalid_data = {
      "ac_charger" => {
        "ports" => "type2",  # Should be an array
        "max_power" => 11.0,
        "usable_phases" => 3
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(invalid_data)
    assert_includes errors, "AC ports must be an array"
  end

  def test_empty_dc_ports
    invalid_data = {
      "ac_charger" => {
        "ports" => [],
        "max_power" => 11.0,
        "usable_phases" => 3
      },
      "dc_charger" => {
        "ports" => [],  # Empty DC ports are not valid
        "max_power" => 150.0
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(invalid_data)
    assert_includes errors, "DC ports cannot be empty when DC charging exists"
  end

  def test_vehicle_required_fields
    @json_data["data"].each do |vehicle|
      assert_vehicle_basic_fields(vehicle)
      assert_charging_ports(vehicle)
      assert_energy_consumption_fields(vehicle["energy_consumption"])
    end
  end

  def test_validates_model_names
    assert_equal true, self.class.valid_model_name?("S+")
    assert_equal true, self.class.valid_model_name?("Model S 2.0")
    assert_equal true, self.class.valid_model_name?("R&D Special")
    assert_equal true, self.class.valid_model_name?("Über-Model")
    assert_equal false, self.class.valid_model_name?("")
    assert_equal false, self.class.valid_model_name?(nil)
    assert_equal false, self.class.valid_model_name?(123) # non-string input
  end

  def test_all_vehicles_have_required_fields
    required_fields = {
      "id" => ->(v) { v.is_a?(String) && !v.empty? },
      "type" => ->(v) { v == "bev" },
      "brand" => ->(v) { v.is_a?(String) && !v.empty? },
      "brand_id" => ->(v) { v.is_a?(String) && !v.empty? },
      "model" => ->(v) { v.is_a?(String) && !v.empty? },
      "vehicle_type" => ->(v) { ["car", "motorbike", "microcar"].include?(v) },
      "variant" => ->(v) { v.is_a?(String) },  # Can be empty but must be present
      "release_year" => ->(v) { v.is_a?(Integer) && v.between?(2010, Time.now.year + 1) },
      "usable_battery_size" => ->(v) { v.is_a?(Numeric) && v.positive? },
      "ac_charger" => ->(v) { 
        v.is_a?(Hash) && 
        v["ports"].is_a?(Array) && 
        v["usable_phases"].is_a?(Integer) && 
        v["max_power"].is_a?(Numeric) && 
        v["power_per_charging_point"].is_a?(Hash)
      },
      "charging_voltage" => ->(v) { [48, 400, 800].include?(v) },
      "energy_consumption" => ->(v) { 
        v.is_a?(Hash) && 
        v["average_consumption"].is_a?(Numeric) && 
        v["average_consumption"].positive?
      }
    }

    @json_data["data"].each do |vehicle|
      required_fields.each do |field, validator|
        assert vehicle.key?(field), 
          "Vehicle #{vehicle['brand']} #{vehicle['model']} is missing required field: #{field}"
        
        assert validator.call(vehicle[field]), 
          "Vehicle #{vehicle['brand']} #{vehicle['model']} has invalid #{field}: #{vehicle[field].inspect}"
      end

      # Additional DC charger validation if present
      if vehicle["dc_charger"]
        assert_dc_charger_valid(vehicle["dc_charger"], "#{vehicle['brand']} #{vehicle['model']}")
      end
    end
  end

  def test_unique_and_valid_uuids
    # Collect all UUIDs from vehicles and brands
    vehicle_ids = @json_data["data"].map { |v| v["id"] }
    brand_ids = @json_data["brands"].map { |b| b["id"] }
    all_ids = vehicle_ids + brand_ids

    # Check for duplicates
    duplicates = all_ids.group_by { |id| id }.select { |_, ids| ids.size > 1 }.keys
    assert_empty duplicates, "Found duplicate UUIDs: #{duplicates}"

    # UUID validation regex
    uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

    # Check each vehicle ID
    @json_data["data"].each do |vehicle|
      assert uuid_regex.match?(vehicle["id"]), 
        "Invalid UUID format for vehicle #{vehicle['brand']} #{vehicle['model']}: #{vehicle['id']}"
      
      assert uuid_regex.match?(vehicle["brand_id"]), 
        "Invalid UUID format for brand_id in vehicle #{vehicle['brand']} #{vehicle['model']}: #{vehicle['brand_id']}"
    end

    # Check each brand ID
    @json_data["brands"].each do |brand|
      assert uuid_regex.match?(brand["id"]), 
        "Invalid UUID format for brand #{brand['name']}: #{brand['id']}"
    end

    # Verify brand_id references exist
    brand_ids_set = Set.new(@json_data["brands"].map { |b| b["id"] })
    @json_data["data"].each do |vehicle|
      assert brand_ids_set.include?(vehicle["brand_id"]), 
        "Vehicle #{vehicle['brand']} #{vehicle['model']} references non-existent brand_id: #{vehicle['brand_id']}"
    end
  end

  private

  def assert_vehicle_basic_fields(vehicle)
    required_fields = %w[
      id brand vehicle_type type brand_id model
      usable_battery_size ac_charger energy_consumption
      charging_voltage
    ]

    required_fields.each do |field|
      assert vehicle.key?(field), 
        "Vehicle missing required field '#{field}' for #{vehicle['brand']} #{vehicle['model']}"
    end

    assert %w[car motorbike microcar].include?(vehicle["vehicle_type"]), 
      "Vehicle type should be 'car', 'motorbike', or 'microcar', got: #{vehicle["vehicle_type"]}"
    
    assert_equal "bev", vehicle["type"], "Type should be 'bev'"
    assert vehicle["usable_battery_size"].is_a?(Numeric), "Battery size should be numeric"
    
    # Updated validation for charging voltage
    valid_voltages = case vehicle["vehicle_type"]
    when "microcar"
      [48, 400]
    else
      [400, 800]
    end
    
    assert valid_voltages.include?(vehicle["charging_voltage"]), 
      "Charging voltage should be one of #{valid_voltages.join('V, ')}V for #{vehicle['vehicle_type']}, got: #{vehicle['charging_voltage']}V"

    assert_charging_ports(vehicle)
  end

  def assert_energy_consumption_fields(consumption)
    assert consumption.key?("average_consumption"), "Missing average consumption"
    assert consumption["average_consumption"].is_a?(Numeric), "Average consumption should be numeric"
  end

  def assert_dc_charger_valid(dc_charger, vehicle_name)
    assert dc_charger.is_a?(Hash), 
      "#{vehicle_name}: DC charger must be a hash"
    
    assert dc_charger["ports"].is_a?(Array) && !dc_charger["ports"].empty?,
      "#{vehicle_name}: DC charger must have non-empty ports array"
    
    assert dc_charger["max_power"].is_a?(Numeric) && dc_charger["max_power"].positive?,
      "#{vehicle_name}: DC charger must have positive max power"
    
    assert dc_charger["charging_curve"].is_a?(Array),
      "#{vehicle_name}: DC charger must have charging curve array"

    if dc_charger["charging_curve"].any?
      dc_charger["charging_curve"].each do |point|
        assert point["percentage"].is_a?(Numeric) && point["percentage"].between?(0, 100),
          "#{vehicle_name}: Invalid charging curve percentage: #{point['percentage']}"
        
        assert point["power"].is_a?(Numeric) && point["power"].positive? && point["power"] <= dc_charger["max_power"],
          "#{vehicle_name}: Invalid charging curve power: #{point['power']}"
      end
    end
  end
end