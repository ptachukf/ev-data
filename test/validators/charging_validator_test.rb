require_relative '../test_helper'

class ChargingValidatorTest < Minitest::Test
  def test_valid_charging_details
    details = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => 11.0,
        "usable_phases" => 3
      },
      "dc_charger" => {
        "ports" => ["ccs"],
        "max_power" => 150.0
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_empty errors, "Expected no validation errors for valid charging details"
  end

  def test_valid_ac_only_charging_details
    details = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => 11.0,
        "usable_phases" => 3
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_empty errors, "Expected no validation errors for valid AC-only charging details"
  end

  def test_invalid_empty_ac_ports
    details = {
      "ac_charger" => {
        "ports" => [],
        "max_power" => 11.0,
        "usable_phases" => 3
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_includes errors, "AC ports cannot be empty"
  end

  def test_invalid_empty_dc_ports
    details = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => 11.0,
        "usable_phases" => 3
      },
      "dc_charger" => {
        "ports" => [],
        "max_power" => 150.0
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_includes errors, "DC ports cannot be empty"
  end

  def test_invalid_ac_phases
    details = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => 11.0,
        "usable_phases" => 4  # Invalid: more than 3 phases
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_includes errors, "AC phases must be between 1 and 3"
  end

  def test_invalid_negative_power
    details = {
      "ac_charger" => {
        "ports" => ["type2"],
        "max_power" => -11.0,  # Invalid: negative power
        "usable_phases" => 3
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_includes errors, "AC power must be positive"
  end

  def test_missing_ac_charger
    details = {
      "dc_charger" => {
        "ports" => ["ccs"],
        "max_power" => 150.0
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_includes errors, "AC charger details are required"
  end
end 