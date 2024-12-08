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

  class DefaultChargingCurve < Array
    def self.create(battery_capacity_kwh, max_power, ac_power, voltage)
      # Define some base thresholds
      small_capacity_threshold = 10
      medium_capacity_threshold = 30
      
      # Adjust the SOC breakpoints based on voltage
      # Higher voltage = can hold max power longer before taper
      # Lower voltage = sooner taper
      
      case voltage
      when 48
        # Treat as small or very small battery with quicker taper
        if battery_capacity_kwh < small_capacity_threshold
          # Tight taper due to low voltage and small capacity
          new([
            { "percentage" => 0,   "power" => (max_power * 1.00) },
            { "percentage" => 50,  "power" => (max_power * 1.00) },
            { "percentage" => 70,  "power" => (max_power * 0.80) },
            { "percentage" => 100, "power" => (max_power * 0.20) }
          ])
        else
          # If somehow battery is larger at 48V (uncommon)
          # still keep a conservative taper
          new([
            { "percentage" => 0,   "power" => max_power },
            { "percentage" => 30,  "power" => max_power },
            { "percentage" => 60,  "power" => (max_power * 0.90) },
            { "percentage" => 80,  "power" => (max_power * 0.50) },
            { "percentage" => 100, "power" => (max_power * 0.20) }
          ])
        end
      when 400
        # Standard approach from earlier logic
        if battery_capacity_kwh < small_capacity_threshold
          new([
            { "percentage" => 0,   "power" => max_power },
            { "percentage" => 70,  "power" => max_power },
            { "percentage" => 100, "power" => (max_power * 0.20) }
          ])
        elsif battery_capacity_kwh <= medium_capacity_threshold
          new([
            { "percentage" => 0,   "power" => max_power },
            { "percentage" => 50,  "power" => max_power },
            { "percentage" => 80,  "power" => (max_power * 0.80) },
            { "percentage" => 100, "power" => (max_power * 0.20) }
          ])
        else
          new([
            { "percentage" => 0,   "power" => (max_power * 1.00) },
            { "percentage" => 30,  "power" => (max_power * 1.00) },
            { "percentage" => 60,  "power" => (max_power * 0.90) },
            { "percentage" => 80,  "power" => [max_power * 0.50, ac_power].max },
            { "percentage" => 100, "power" => [max_power * 0.20, ac_power].max }
          ])
        end
      when 800
        # High voltage: sustain high power longer
        if battery_capacity_kwh < small_capacity_threshold
          # Even small at 800V is unusual, but let's still allow a good initial hold
          new([
            { "percentage" => 0,   "power" => max_power },
            { "percentage" => 70,  "power" => max_power },
            { "percentage" => 100, "power" => (max_power * 0.20) }
          ])
        elsif battery_capacity_kwh <= medium_capacity_threshold
          # Medium battery at high voltage: extend full power phase a bit
          new([
            { "percentage" => 0,   "power" => max_power },
            { "percentage" => 60,  "power" => max_power },
            { "percentage" => 80,  "power" => [max_power * 0.50, ac_power].max },
            { "percentage" => 100, "power" => [max_power * 0.20, ac_power].max }
          ])
        else
          # Large battery, high voltage: longer full power, gentler tapers
          new([
            { "percentage" => 0,   "power" => (max_power * 1.00) },
            { "percentage" => 40,  "power" => (max_power * 1.00) },
            { "percentage" => 70,  "power" => (max_power * 0.90) },
            { "percentage" => 85,  "power" => [max_power * 0.50, ac_power].max },
            { "percentage" => 100, "power" => [max_power * 0.20, ac_power].max }
          ])
        end
      else
        # Default to 400V logic if unknown
        if battery_capacity_kwh < small_capacity_threshold
          new([
            { "percentage" => 0,   "power" => max_power },
            { "percentage" => 70,  "power" => max_power },
            { "percentage" => 100, "power" => (max_power * 0.20) }
          ])
        elsif battery_capacity_kwh <= medium_capacity_threshold
          new([
            { "percentage" => 0,   "power" => max_power },
            { "percentage" => 50,  "power" => max_power },
            { "percentage" => 80,  "power" => [max_power * 0.50, ac_power].max },
            { "percentage" => 100, "power" => [max_power * 0.20, ac_power].max }
          ])
        else
          new([
            { "percentage" => 0,   "power" => (max_power * 1.00) },
            { "percentage" => 30,  "power" => (max_power * 1.00) },
            { "percentage" => 60,  "power" => (max_power * 0.90) },
            { "percentage" => 80,  "power" => [max_power * 0.50, ac_power].max },
            { "percentage" => 100, "power" => [max_power * 0.20, ac_power].max }
         ])
        end
      end
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
