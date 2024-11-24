class Vehicle
  attr_reader :data

  def initialize
    @data = {
      "id" => SecureRandom.uuid,
      "type" => "bev"
    }
  end

  def add_brand(brand, brand_id)
    @data.merge!({
      "brand" => brand,
      "brand_id" => brand_id
    })
  end

  def add_model(model)
    @data["model"] = model
  end

  def add_vehicle_type(type)
    @data["vehicle_type"] = type
  end

  def add_variant_details(details)
    @data.merge!(details)
  end

  def add_charging_details(details)
    @data.merge!(details)
  end

  def add_energy_consumption(consumption)
    @data["energy_consumption"] = {
      "average_consumption" => consumption
    }
  end

  def add_charging_curve(curve, is_default = false)
    return unless @data["dc_charger"]
    
    @data["dc_charger"].merge!({
      "charging_curve" => curve,
      "is_default_charging_curve" => is_default
    })
  end

  def add_voltage_architecture(voltage)
    @data["voltage_architecture"] = voltage
  end
end
