module Validators
  module ClassMethods
    def valid_brand_name?(name)
      name.is_a?(String) && !name.empty?
    end

    def valid_model_name?(name)
      name.is_a?(String) && !name.empty?
    end

    def valid_year?(year)
      return false unless year.is_a?(Integer)
      year.between?(2010, Time.now.year + 1)
    end

    def valid_battery_size?(size)
      return false unless size.is_a?(Numeric)
      size.positive?
    end

    def valid_consumption?(consumption)
      return false unless consumption.is_a?(Numeric)
      consumption.positive?
    end

    def valid_charging_power?(power)
      return false unless power.is_a?(Numeric)
      power.positive?
    end

    def valid_charging_percentage?(percentage)
      return false unless percentage.is_a?(Numeric)
      percentage.between?(0, 100)
    end

    def valid_ac_ports?(ports)
      return false if ports.nil?
      return true if ports.empty?
      ports.all? { |port| ChargingDetails::AC_PORTS.include?(port) }
    end

    def valid_dc_ports?(ports)
      return false if ports.nil? || ports.empty?
      ports.all? { |port| ChargingDetails::DC_PORTS.include?(port) }
    end

    def valid_phases?(phases)
      return false unless phases.is_a?(Integer)
      [1, 2, 3].include?(phases)
    end

    def valid_charging_voltage?(voltage, vehicle_type)
      valid_voltages = case vehicle_type
      when "microcar"
        [48, 400]
      else
        [400, 800]
      end
      
      valid_voltages.include?(voltage)
    end

    def valid_charging_curve?(curve, max_power)
      return false if curve.nil? || curve.empty?
      
      # Check if points are in ascending order by percentage
      percentages = curve.map { |point| point["percentage"] }
      return false unless percentages == percentages.sort
      
      # Validate each point
      curve.all? do |point|
        valid_charging_percentage?(point["percentage"]) &&
          valid_charging_power?(point["power"]) &&
          point["power"] <= max_power
      end
    end

    def valid_vehicle_type?(type)
      ["car", "motorbike", "microcar"].include?(type)
    end

    def valid_vehicle_data?(data)
      required_fields = %w[
        id brand model type vehicle_type brand_id
        usable_battery_size ac_charger energy_consumption
        charging_voltage
      ]

      # Check required fields exist
      return false unless required_fields.all? { |field| data.key?(field) }

      # Validate individual fields
      valid_brand_name?(data["brand"]) &&
        valid_model_name?(data["model"]) &&
        data["type"] == "bev" &&
        valid_vehicle_type?(data["vehicle_type"]) &&
        valid_battery_size?(data["usable_battery_size"]) &&
        valid_charging_voltage?(data["charging_voltage"], data["vehicle_type"]) &&
        valid_ac_charger?(data["ac_charger"]) &&
        valid_dc_charger?(data["dc_charger"])
    end

    private

    def valid_ac_charger?(charger)
      return false unless charger.is_a?(Hash)
      
      valid_ac_ports?(charger["ports"]) &&
        valid_phases?(charger["usable_phases"]) &&
        valid_charging_power?(charger["max_power"]) &&
        valid_power_per_charging_point?(charger["power_per_charging_point"])
    end

    def valid_dc_charger?(charger)
      return true if charger.nil? # DC charger is optional
      return false unless charger.is_a?(Hash)
      
      valid_dc_ports?(charger["ports"]) &&
        valid_charging_power?(charger["max_power"]) &&
        valid_charging_curve?(charger["charging_curve"], charger["max_power"])
    end

    def valid_power_per_charging_point?(power_points)
      return false unless power_points.is_a?(Hash)
      
      required_points = %w[2.0 2.3 3.7 7.4 11 16 22 43]
      required_points.all? { |point| power_points.key?(point) } &&
        power_points.values.all? { |power| valid_charging_power?(power) }
    end
  end

  # Create a singleton instance for module-level validation
  class << self
    include ClassMethods
  end

  class ChargingValidator
    def self.validate_charging_details(details)
      errors = []
      
      # AC charging validation
      if details["ac_charger"]
        errors.concat(validate_ac_charging(details["ac_charger"]))
      else
        errors << "AC charger details are required"
      end

      # DC charging validation (optional)
      if details["dc_charger"]
        errors.concat(validate_dc_charging(details["dc_charger"]))
      end

      errors
    end

    private

    def self.validate_ac_charging(ac_charger)
      errors = []
      
      # Validate ports array exists (but can be empty)
      unless ac_charger["ports"].is_a?(Array)
        errors << "AC ports must be an array"
      end

      # Validate other AC charging fields
      errors << "AC power must be positive" unless ac_charger["max_power"].positive?
      errors << "AC phases must be between 1 and 3" unless (1..3).include?(ac_charger["usable_phases"])

      errors
    end

    def self.validate_dc_charging(dc_charger)
      errors = []
      
      # Validate ports
      unless dc_charger["ports"].is_a?(Array)
        errors << "DC ports must be an array"
        return errors
      end

      errors << "DC ports cannot be empty when DC charging exists" if dc_charger["ports"].empty?
      errors << "DC power must be positive" unless dc_charger["max_power"].positive?

      if dc_charger["charging_curve"]
        errors.concat(validate_charging_curve(dc_charger["charging_curve"], dc_charger["max_power"]))
      end

      errors
    end

    def self.validate_charging_curve(curve, max_power)
      # ... existing charging curve validation ...
    end
  end
end
