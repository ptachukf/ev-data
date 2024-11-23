require_relative '../test_helper'

class EVDataTest < Minitest::Test
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

  private

  def assert_vehicle_basic_fields(vehicle)
    required_fields = %w[
      id brand vehicle_type type brand_id model
      usable_battery_size ac_charger energy_consumption
      charging_voltage
    ]

    required_fields.each do |field|
      assert vehicle.key?(field), "Vehicle missing required field: #{field}"
    end

    # Update to allow all three vehicle types
    assert %w[car motorbike quadricycle].include?(vehicle["vehicle_type"]), 
      "Vehicle type should be 'car', 'motorbike', or 'quadricycle', got: #{vehicle["vehicle_type"]}"
    
    assert_equal "bev", vehicle["type"], "Type should be 'bev'"
    assert vehicle["usable_battery_size"].is_a?(Numeric), "Battery size should be numeric"
    assert vehicle["charging_voltage"].is_a?(Numeric), "Charging voltage should be numeric"

    # Add ports validation
    assert_charging_ports(vehicle)
  end

  def assert_energy_consumption_fields(consumption)
    assert consumption.key?("average_consumption"), "Missing average consumption"
    assert consumption["average_consumption"].is_a?(Numeric), "Average consumption should be numeric"
  end
end