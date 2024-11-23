require 'minitest/autorun'
require 'json'
require 'fileutils'
require 'securerandom'
require_relative '../lib/vehicle_creator/data_store'
require_relative '../lib/vehicle_creator/charging_details'

class DataStoreTest < Minitest::Test
  def setup
    @test_data_file = 'test/fixtures/test-ev-data.json'
    @initial_data = {
      "meta" => {
        "updated_at" => "2024-01-01T00:00:00Z",
        "overall_count" => 1
      },
      "data" => [
        {
          "id" => "test-id-1",
          "brand" => "Test Brand",
          "model" => "Test Model",
          "type" => "bev",
          "vehicle_type" => "car",
          "brand_id" => "test-brand-id-1"
        }
      ]
    }
    
    FileUtils.mkdir_p(File.dirname(@test_data_file))
    File.write(@test_data_file, JSON.pretty_generate(@initial_data))
    @data_store = DataStore.new(@test_data_file)
  end

  def teardown
    File.delete(@test_data_file) if File.exist?(@test_data_file)
  end

  def test_save_vehicle
    new_vehicle = {
      "id" => "test-id-2",
      "brand" => "New Brand",
      "model" => "New Model",
      "type" => "bev",
      "vehicle_type" => "car"
    }
    
    @data_store.save_vehicle(new_vehicle)
    saved_data = JSON.parse(File.read(@test_data_file))
    
    assert_equal 2, saved_data["data"].length
    assert_equal 2, saved_data["meta"]["overall_count"]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/, saved_data["meta"]["updated_at"])
  end

  def test_find_or_create_brand_id_existing
    brand_id = @data_store.find_or_create_brand_id("Test Brand")
    assert_equal "test-brand-id-1", brand_id
  end

  def test_find_or_create_brand_id_new
    SecureRandom.stub :uuid, "new-uuid" do
      brand_id = @data_store.find_or_create_brand_id("New Brand")
      assert_equal "new-uuid", brand_id
    end
  end
end

class ChargingDetailsTest < Minitest::Test
  def test_generate_power_per_charging_point
    result = ChargingDetails.generate_power_per_charging_point(11.0)
    
    expected = {
      "2.0" => 2.0,
      "2.3" => 2.3,
      "3.7" => 3.7,
      "7.4" => 7.4,
      "11" => 11.0,
      "16" => 11.0,  # Limited by max_power
      "22" => 11.0,  # Limited by max_power
      "43" => 11.0   # Limited by max_power
    }
    
    assert_equal expected, result
  end

  def test_generate_power_per_charging_point_with_lower_max
    result = ChargingDetails.generate_power_per_charging_point(7.4)
    
    expected = {
      "2.0" => 2.0,
      "2.3" => 2.3,
      "3.7" => 3.7,
      "7.4" => 7.4,
      "11" => 7.4,   # Limited by max_power
      "16" => 7.4,   # Limited by max_power
      "22" => 7.4,   # Limited by max_power
      "43" => 7.4    # Limited by max_power
    }
    
    assert_equal expected, result
  end
end 