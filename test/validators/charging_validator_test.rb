require_relative '../test_helper'

class ChargingValidatorTest < Minitest::Test
  def test_valid_charging_details
    valid_data = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => 11.0,
        "usable_phases" => 3,
        "power_per_charging_point" => {
          "2.0" => 2.0,
          "2.3" => 2.3,
          "3.7" => 3.7,
          "7.4" => 7.4,
          "11" => 11.0,
          "16" => 11.0,
          "22" => 11.0,
          "43" => 11.0
        }
      },
      "dc_charger" => {
        "ports" => ["ccs"],
        "max_power" => 150.0,
        "charging_curve" => [
          {"percentage" => 0, "power" => 150.0},
          {"percentage" => 80, "power" => 70.0}
        ]
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(valid_data)
    assert_empty errors, "Expected no validation errors for valid charging details"
  end

  def test_valid_ac_only_charging_details
    valid_data = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => 11.0,
        "usable_phases" => 3,
        "power_per_charging_point" => {
          "2.0" => 2.0,
          "2.3" => 2.3,
          "3.7" => 3.7,
          "7.4" => 7.4,
          "11" => 11.0,
          "16" => 11.0,
          "22" => 11.0,
          "43" => 11.0
        }
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(valid_data)
    assert_empty errors, "Expected no validation errors for valid AC-only charging details"
  end

  def test_missing_ac_charger
    invalid_data = {
      "ac_charger" => nil
    }

    errors = Validators::ChargingValidator.validate_charging_details(invalid_data)
    assert_includes errors, "AC charger must be present"
  end

  def test_invalid_ac_phases
    invalid_data = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => 11.0,
        "usable_phases" => 4,  # Invalid: more than 3 phases
        "power_per_charging_point" => {
          "2.0" => 2.0,
          "2.3" => 2.3,
          "3.7" => 3.7,
          "7.4" => 7.4,
          "11" => 11.0,
          "16" => 11.0,
          "22" => 11.0,
          "43" => 11.0
        }
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(invalid_data)
    assert_includes errors, "AC charger must have valid usable phases (1-3)"
  end

  def test_invalid_negative_power
    invalid_data = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => -11.0,  # Invalid: negative power
        "usable_phases" => 3,
        "power_per_charging_point" => {
          "2.0" => 2.0,
          "2.3" => 2.3,
          "3.7" => 3.7,
          "7.4" => 7.4,
          "11" => 11.0,
          "16" => 11.0,
          "22" => 11.0,
          "43" => 11.0
        }
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(invalid_data)
    assert_includes errors, "AC charger must have positive max power"
  end

  def test_missing_power_points
    invalid_data = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => 11.0,
        "usable_phases" => 3
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(invalid_data)
    assert_includes errors, "Missing power per charging point"
  end

  def test_invalid_power_values
    invalid_data = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => 11.0,
        "usable_phases" => 3,
        "power_per_charging_point" => {
          "2.0" => -2.0,  # Invalid: negative power
          "2.3" => 0.0,   # Invalid: zero power
          "3.7" => 12.0,  # Invalid: exceeds max power
          "7.4" => 7.4,   # Valid
          "11" => 11.0,   # Valid
          "16" => 11.0,   # Valid
          "22" => 11.0,   # Valid
          "43" => 11.0    # Valid
        }
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(invalid_data)
    assert_includes errors, "Invalid power value for point 2.0"
    assert_includes errors, "Invalid power value for point 2.3"
    assert_includes errors, "Invalid power value for point 3.7"
  end

  def test_invalid_dc_charging_curve
    invalid_data = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => 11.0,
        "usable_phases" => 3,
        "power_per_charging_point" => {
          "2.0" => 2.0,
          "2.3" => 2.3,
          "3.7" => 3.7,
          "7.4" => 7.4,
          "11" => 11.0,
          "16" => 11.0,
          "22" => 11.0,
          "43" => 11.0
        }
      },
      "dc_charger" => {
        "ports" => ["ccs"],
        "max_power" => 150.0,
        "charging_curve" => [
          {"percentage" => -10, "power" => 150.0},  # Invalid: negative percentage
          {"percentage" => 110, "power" => 70.0}    # Invalid: percentage > 100
        ]
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(invalid_data)
    assert_includes errors, "Invalid charging curve percentage: -10"
    assert_includes errors, "Invalid charging curve percentage: 110"
  end
end 