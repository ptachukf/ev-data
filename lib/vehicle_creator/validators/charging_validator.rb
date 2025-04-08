module Validators
  module ChargingValidator
    def self.validate_charging_details(data)
      errors = []
      
      if data['ac_charger'].nil?
        errors << "AC charger must be present"
      elsif ac_charger = data['ac_charger']
        errors.concat(validate_ac_charger(ac_charger))
      end
      
      if dc_charger = data['dc_charger']
        errors.concat(validate_dc_charger(dc_charger))
      end
      
      errors
    end

    def self.validate_ac_charger(ac_charger)
      errors = []
      
      # Validate ports array
      unless ac_charger['ports'].is_a?(Array)
        errors << "AC ports must be an array"
      end

      # Validate usable phases
      unless ac_charger['usable_phases'].is_a?(Integer) && (1..3).include?(ac_charger['usable_phases'])
        errors << "AC charger must have valid usable phases (1-3)"
      end

      # Validate max power
      unless ac_charger['max_power'].is_a?(Numeric) && ac_charger['max_power'].positive?
        errors << "AC charger must have positive max power"
      end

      # Validate power per charging point
      if points = ac_charger['power_per_charging_point']
        unless points.is_a?(Hash) && points.values.all? { |v| v.is_a?(Numeric) && v.positive? }
          errors << "Invalid power per charging point structure"
        end

        if ac_charger['max_power'].is_a?(Numeric)
          points.each do |point, power|
            unless power.is_a?(Numeric) && power.positive? && power <= ac_charger['max_power']
              errors << "Invalid power value for point #{point}"
            end
          end

          # Validate required power points
          required_points = ["2.0", "2.3", "3.7", "7.4", "11", "16", "22", "43"]
          missing_points = required_points - points.keys
          unless missing_points.empty?
            errors << "Missing required power points: #{missing_points.join(', ')}"
          end
        end
      else
        errors << "Missing power per charging point"
      end

      errors
    end

    def self.validate_dc_charger(dc_charger)
      errors = []
      
      # Validate ports array
      unless dc_charger['ports'].is_a?(Array)
        errors << "DC ports must be an array"
      end

      if dc_charger['ports'].empty?
        errors << "DC ports cannot be empty when DC charging exists"
      end

      # Validate max power
      unless dc_charger['max_power'].is_a?(Numeric) && dc_charger['max_power'].positive?
        errors << "DC charger must have positive max power"
      end

      # Validate charging curve if present
      if curve = dc_charger['charging_curve']
        unless curve.is_a?(Array)
          errors << "Charging curve must be an array"
        end

        curve.each do |point|
          unless point['percentage'].is_a?(Numeric) && point['percentage'].between?(0, 100)
            errors << "Invalid charging curve percentage: #{point['percentage']}"
          end

          unless point['power'].is_a?(Numeric) && point['power'].positive? && point['power'] <= dc_charger['max_power']
            errors << "Invalid charging curve power: #{point['power']} kW exceeds the max power of #{dc_charger['max_power']} kW"
          end
        end
      end

      errors
    end
  end
end 