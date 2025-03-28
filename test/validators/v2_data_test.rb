require_relative '../test_helper'
require 'set'

class V2DataTest < Minitest::Test
  def setup
    @brands_data = JSON.parse(File.read('data/v2/brands.json'))
    @validator = Validators::V2Validator
  end

  def test_brands_file_structure
    errors = @validator.validate_brands_file('data/v2/brands.json')
    assert_empty errors, "Expected no validation errors in brands.json, got: #{errors}"
  end

  def test_brand_references_exist
    # Get all brand IDs from brands.json
    brand_ids = Set.new(@brands_data['brands'].map { |b| b['id'] })
    
    # Check each models file
    @brands_data['brands'].each do |brand|
      models_path = "data/v2/#{brand['models_file']}"
      models_data = JSON.parse(File.read(models_path))
      
      # Verify brand ID consistency
      assert_equal brand['id'], models_data['brand_id'], 
        "Brand ID mismatch in #{models_path}"
      
      # Verify brand name consistency
      assert_equal brand['name'], models_data['brand_name'],
        "Brand name mismatch in #{models_path}"
      
      # Check each vehicle in the models file
      models_data['models'].each do |vehicle|
        assert_equal brand['id'], vehicle['brand_id'],
          "Vehicle brand ID mismatch in #{models_path}"
        assert_equal brand['name'], vehicle['brand'],
          "Vehicle brand name mismatch in #{models_path}"
      end
    end
  end

  def test_unique_vehicle_ids
    all_vehicle_ids = Set.new
    
    @brands_data['brands'].each do |brand|
      models_path = "data/v2/#{brand['models_file']}"
      models_data = JSON.parse(File.read(models_path))
      
      models_data['models'].each do |vehicle|
        refute all_vehicle_ids.include?(vehicle['id']),
          "Duplicate vehicle ID found: #{vehicle['id']}"
        all_vehicle_ids.add(vehicle['id'])
      end
    end
  end

  def test_vehicle_required_fields
    @brands_data['brands'].each do |brand|
      models_path = "data/v2/#{brand['models_file']}"
      errors = @validator.validate_models_file(models_path, brand['id'])
      assert_empty errors, "Validation errors in #{models_path}: #{errors}"
    end
  end

  def test_charging_details
    @brands_data['brands'].each do |brand|
      models_path = "data/v2/#{brand['models_file']}"
      models_data = JSON.parse(File.read(models_path))
      
      models_data['models'].each do |vehicle|
        # AC charger validation
        if vehicle['ac_charger']
          assert vehicle['ac_charger']['ports'].is_a?(Array),
            "AC ports must be an array for #{vehicle['brand']} #{vehicle['model']}"
        end

        # DC charger validation
        if vehicle['dc_charger']
          assert vehicle['dc_charger']['ports'].is_a?(Array),
            "DC ports must be an array for #{vehicle['brand']} #{vehicle['model']}"
          refute vehicle['dc_charger']['ports'].empty?,
            "DC ports cannot be empty for #{vehicle['brand']} #{vehicle['model']}"
        end
      end
    end
  end

  def test_overall_count_matches
    total_vehicles = 0
    
    @brands_data['brands'].each do |brand|
      models_path = "data/v2/#{brand['models_file']}"
      models_data = JSON.parse(File.read(models_path))
      total_vehicles += models_data['models'].size
    end
    
    assert_equal @brands_data['meta']['overall_count'], total_vehicles,
      "Overall count in meta doesn't match actual vehicle count"
  end

  def test_valid_file_references
    @brands_data['brands'].each do |brand|
      models_path = "data/v2/#{brand['models_file']}"
      assert File.exist?("data/v2/#{brand['models_file']}"),
        "Referenced file doesn't exist: #{models_path}"
    end
  end

  def test_consistent_charging_voltages
    @brands_data['brands'].each do |brand|
      models_path = "data/v2/#{brand['models_file']}"
      models_data = JSON.parse(File.read(models_path))
      
      models_data['models'].each do |vehicle|
        valid_voltages = case vehicle['vehicle_type']
        when 'microcar'
          [48, 400]
        else
          [400, 800]
        end
        
        assert valid_voltages.include?(vehicle['charging_voltage']),
          "Invalid charging voltage #{vehicle['charging_voltage']}V for #{vehicle['vehicle_type']} #{vehicle['brand']} #{vehicle['model']}"
      end
    end
  end
end 