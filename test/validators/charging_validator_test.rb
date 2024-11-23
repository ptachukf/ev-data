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
        "ports" => [],
        "max_power" => 11.0,
        "usable_phases" => 3
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_empty errors, "Expected no validation errors for valid AC-only charging details"
  end

  def test_invalid_ac_ports_not_array
    details = {
      "ac_charger" => {
        "ports" => "type2",
        "max_power" => 11.0,
        "usable_phases" => 3
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_includes errors, "AC ports must be an array"
  end

  def test_invalid_dc_ports_empty
    details = {
      "ac_charger" => {
        "ports" => [],
        "max_power" => 11.0,
        "usable_phases" => 3
      },
      "dc_charger" => {
        "ports" => [],
        "max_power" => 150.0
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_includes errors, "DC ports cannot be empty when DC charging exists"
  end

  def test_invalid_ac_phases
    details = {
      "ac_charger" => {
        "ports" => [],
        "max_power" => 11.0,
        "usable_phases" => 4
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_includes errors, "AC phases must be between 1 and 3"
  end

  def test_invalid_negative_power
    details = {
      "ac_charger" => {
        "ports" => [],
        "max_power" => -11.0,
        "usable_phases" => 3
      }
    }

    errors = Validators::ChargingValidator.validate_charging_details(details)
    assert_includes errors, "AC power must be positive"
  end
end 