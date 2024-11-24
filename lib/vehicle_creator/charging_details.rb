class ChargingDetails
  AC_PORTS = ["type1", "type2"]
  DC_PORTS = ["ccs", "chademo", "tesla_suc"]
  CHARGING_VOLTAGES = [230, 400, 800]

  def self.calculate_power_per_point(max_power)
    {
      "2.0" => [2.0, max_power].min,
      "2.3" => [2.3, max_power].min,
      "3.7" => [3.7, max_power].min,
      "7.4" => [7.4, max_power].min,
      "11" => [11.0, max_power].min,
      "16" => [16.0, max_power].min,
      "22" => [22.0, max_power].min,
      "43" => [43.0, max_power].min
    }
  end

  def self.create_ac_charger(ports, phases, max_power)
    {
      "ports" => ports,
      "usable_phases" => phases,
      "max_power" => max_power,
      "power_per_charging_point" => calculate_power_per_point(max_power)
    }
  end

  def self.create_dc_charger(ports, max_power)
    {
      "ports" => ports,
      "max_power" => max_power,
      "charging_curve" => [],  # Will be filled later
      "is_default_charging_curve" => false
    }
  end

  def self.default_charging_curve(max_power, ac_power)
    [
      { "percentage" => 0, "power" => max_power * 0.95 },
      { "percentage" => 50, "power" => max_power },
      { "percentage" => 80, "power" => [max_power * 0.5, ac_power].max },
      { "percentage" => 100, "power" => [max_power * 0.2, ac_power].max }
    ]
  end

  def self.validate_charging_curve(curve, max_power)
    return false if curve.empty?
    
    curve.all? do |point|
      point["percentage"].between?(0, 100) &&
      point["power"].between?(0, max_power)
    end
  end
end
