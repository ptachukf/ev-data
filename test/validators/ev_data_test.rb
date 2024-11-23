require_relative '../test_helper'

class EVDataTest < Minitest::Test
  def setup
    project_root = find_project_root
    file_path = File.join(project_root, 'data/ev-data.json')
    
    unless File.exist?(file_path)
      raise "Could not find JSON file at #{file_path}"
    end
    
    @json_data = JSON.parse(File.read(file_path))
  end

  def test_valid_json_structure
    assert_equal "data", @json_data.keys.first, "Root should have 'data' key"
    assert @json_data["data"].is_a?(Array), "Data should be an array"
  end

  def test_vehicle_required_fields
    @json_data["data"].each do |vehicle|
      # Basic fields
      assert_vehicle_basic_fields(vehicle)
      
      # AC charger fields
      assert_ac_charger_fields(vehicle["ac_charger"])
      
      # DC charger fields (can be null or have ports)
      if vehicle["dc_charger"]
        assert_dc_charger_fields(vehicle["dc_charger"])
        assert_charging_ports(vehicle)
      end
      
      # Energy consumption
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

  def assert_ac_charger_fields(ac_charger)
    required_fields = %w[
      usable_phases ports max_power power_per_charging_point
    ]

    required_fields.each do |field|
      assert ac_charger.key?(field), "AC charger missing required field: #{field}"
    end

    assert ac_charger["ports"].is_a?(Array), "Ports should be an array"
    assert ac_charger["power_per_charging_point"].is_a?(Hash), "Power per charging point should be a hash"
  end

  def assert_dc_charger_fields(dc_charger)
    required_fields = %w[
      ports max_power charging_curve is_default_charging_curve
    ]

    required_fields.each do |field|
      assert dc_charger.key?(field), "DC charger missing required field: #{field}"
    end

    assert dc_charger["ports"].is_a?(Array), "Ports should be an array"
    assert dc_charger["charging_curve"].is_a?(Array), "Charging curve should be an array"
    
    dc_charger["charging_curve"].each do |point|
      assert point.key?("percentage"), "Charging curve point missing percentage"
      assert point.key?("power"), "Charging curve point missing power"
    end
  end

  def assert_energy_consumption_fields(consumption)
    assert consumption.key?("average_consumption"), "Missing average consumption"
    assert consumption["average_consumption"].is_a?(Numeric), "Average consumption should be numeric"
  end

  def assert_charging_ports(vehicle)
    # AC charger must have ports
    if vehicle["ac_charger"]
      assert vehicle["ac_charger"]["ports"].is_a?(Array), "AC ports must be an array"
      assert !vehicle["ac_charger"]["ports"].empty?, "AC ports cannot be empty"
    end

    # DC charger must have ports if it exists and isn't null
    if vehicle["dc_charger"] && !vehicle["dc_charger"].nil?
      assert vehicle["dc_charger"]["ports"].is_a?(Array), "DC ports must be an array"
      assert !vehicle["dc_charger"]["ports"].empty?, "DC ports cannot be empty"
      
      # If we have a charging curve, we must have ports
      if vehicle["dc_charger"]["charging_curve"]
        assert !vehicle["dc_charger"]["ports"].empty?, 
          "DC ports cannot be empty when charging curve exists"
      end
    end
  end

  def find_project_root
    current_dir = File.dirname(__FILE__)
    while !File.exist?(File.join(current_dir, 'data/ev-data.json'))
      current_dir = File.dirname(current_dir)
      raise "Could not find project root with ev-data.json" if current_dir == '/'
    end
    current_dir
  end
end