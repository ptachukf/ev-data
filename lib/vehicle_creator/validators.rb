class Validators
  class << self
    def valid_brand_name?(name)
      return false if name.nil? || name.empty?
      name.match?(/\A[A-Za-z0-9\s\-]+\z/)
    end

    def valid_model_name?(name)
      return false if name.nil? || name.empty?
      name.match?(/\A[A-Za-z0-9\s\-]+\z/)
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
      return false if ports.nil? || ports.empty?
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

    def valid_charging_voltage?(voltage)
      ChargingDetails::CHARGING_VOLTAGES.include?(voltage)
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
      ["car", "motorbike"].include?(type)
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
        valid_charging_voltage?(data["charging_voltage"]) &&
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
end
