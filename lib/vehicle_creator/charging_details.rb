class ChargingDetails
  AC_PORTS = ["type1", "type2"]
  DC_PORTS = ["ccs", "chademo", "tesla_suc"]
  CHARGING_VOLTAGES = [48, 400, 800]

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

  def self.create_dc_charger(ports, max_power, curve = nil)
    {
      "ports" => ports,
      "max_power" => max_power,
      "charging_curve" => curve || [],
      "is_default_charging_curve" => curve.nil? ? false : curve.is_a?(DefaultChargingCurve)
    }
  end
  
  def self.create_charging_curve_points(max_power, points)
    points.map do |point|
      {
        "percentage" => point[:soc],
        "power" => max_power * point[:power_factor]
      }
    end
  end

  def self.get_curve_points(battery_capacity_kwh, voltage)
    small_capacity_threshold = 10
    medium_capacity_threshold = 30

    case voltage 
    when 48
      if battery_capacity_kwh < small_capacity_threshold
        [
          {soc: 0, power_factor: 1.0},
          {soc: 50, power_factor: 1.0},
          {soc: 70, power_factor: 0.8},
          {soc: 100, power_factor: 0.2}
        ]
      else
        [
          {soc: 0, power_factor: 1.0},
          {soc: 30, power_factor: 1.0}, 
          {soc: 60, power_factor: 0.9},
          {soc: 80, power_factor: 0.5},
          {soc: 100, power_factor: 0.2}
        ]
      end
    when 400
      if battery_capacity_kwh < small_capacity_threshold
        [
          {soc: 0, power_factor: 1.0},
          {soc: 70, power_factor: 1.0},
          {soc: 100, power_factor: 0.2}
        ]
      elsif battery_capacity_kwh <= medium_capacity_threshold
        [
          {soc: 0, power_factor: 1.0},
          {soc: 50, power_factor: 1.0},
          {soc: 80, power_factor: 0.8}, 
          {soc: 100, power_factor: 0.2}
        ]
      else
        [
          {soc: 0, power_factor: 1.0},
          {soc: 30, power_factor: 1.0},
          {soc: 60, power_factor: 0.9},
          {soc: 80, power_factor: 0.5},
          {soc: 100, power_factor: 0.2}
        ]
      end
    end
  end

  class DefaultChargingCurve < Array
    def self.create(battery_capacity_kwh, max_power, ac_power, voltage)
      # Define some base thresholds
      points = ChargingDetails.get_curve_points(battery_capacity_kwh, voltage)
      new(ChargingDetails.create_charging_curve_points(max_power, points))
    end
  end

  def self.validate_charging_curve(curve, max_power)
    return false if curve.empty?
    
    curve.all? do |point|
      point["percentage"].between?(0, 100) &&
      point["power"].between?(0, max_power)
    end
  end
end
