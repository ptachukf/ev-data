class CLI
  EXIT_OPTION = "❌ Exit"
  BACK_OPTION = "↩️  Go back"
  
  def initialize(prompt)
    @prompt = prompt
  end

  def select_brand(existing_brands)
    choices = ["Choose existing brand", "Add new brand", EXIT_OPTION]
    action = @prompt.select("Select action for brand:", choices)
    
    case action
    when "Choose existing brand"
      choices = existing_brands + [BACK_OPTION, EXIT_OPTION]
      @prompt.select("Select brand:", choices)
    when "Add new brand"
      @prompt.ask("Enter new brand name (or 'exit'):", 
        validate: /\A[A-Za-z0-9\s\-]+\z/,
        messages: { valid?: "Brand name can only contain letters, numbers, spaces, and hyphens" })
    else
      action
    end
  end

  def select_model(existing_models)
    choices = ["Choose existing model", "Add new model", BACK_OPTION, EXIT_OPTION]
    action = @prompt.select("Select action for model:", choices)
    
    case action
    when "Choose existing model"
      return BACK_OPTION if existing_models.empty?
      choices = existing_models + [BACK_OPTION, EXIT_OPTION]
      @prompt.select("Select model:", choices)
    when "Add new model"
      @prompt.ask("Enter new model name (or 'back'/'exit'):",
        validate: /\A[A-Za-z0-9\s\-]+\z/,
        messages: { valid?: "Model name can only contain letters, numbers, spaces, and hyphens" })
    else
      action
    end
  end

  def select_vehicle_type
    choices = ["car", "motorbike", BACK_OPTION, EXIT_OPTION]
    @prompt.select("Select vehicle type:", choices)
  end

  def collect_and_add_details(vehicle)
    # Variant details
    variant = collect_variant_details
    return false if [EXIT_OPTION, BACK_OPTION].include?(variant)
    vehicle.add_variant_details(variant)

    # Charging details
    charging = collect_charging_details
    return false if [EXIT_OPTION, BACK_OPTION].include?(charging)
    vehicle.add_charging_details(charging)

    # Charging curve if DC charging exists
    if charging["dc_charger"]
      curve = collect_charging_curve(charging["dc_charger"]["max_power"])
      return false if [EXIT_OPTION, BACK_OPTION].include?(curve)
      vehicle.add_charging_curve(curve)
    end

    true
  end

  def collect_variant_details
    variant = @prompt.ask("Enter variant name (or 'back'/'exit'):")
    return variant if [EXIT_OPTION, BACK_OPTION].include?(variant)

    year = @prompt.ask("Enter release year (or 'back'/'exit'):",
      convert: :integer,
      validate: ->(v) { v.to_s.downcase == 'exit' || v.to_s.downcase == 'back' || v.to_i.between?(2010, Time.now.year + 1) })
    return year if [EXIT_OPTION, BACK_OPTION].include?(year)

    battery = @prompt.ask("Enter usable battery size (kWh) (or 'back'/'exit'):",
      convert: :float,
      validate: ->(v) { v.to_f > 0 })
    return battery if [EXIT_OPTION, BACK_OPTION].include?(battery)

    consumption = @prompt.ask("Enter average consumption (kWh/100km) (or 'back'/'exit'):",
      convert: :float,
      validate: ->(v) { v.to_f > 0 })
    return consumption if [EXIT_OPTION, BACK_OPTION].include?(consumption)

    {
      "variant" => variant,
      "release_year" => year,
      "usable_battery_size" => battery,
      "energy_consumption" => {
        "average_consumption" => consumption
      }
    }
  end

  def collect_charging_details
    # AC charging
    ac_ports = @prompt.multi_select("Select AC ports (at least one required):", ChargingDetails::AC_PORTS)
    ac_phases = @prompt.select("Select AC phases:", [1, 2, 3])
    ac_power = @prompt.ask("Enter max AC power (kW):",
      convert: :float,
      validate: ->(v) { v.to_f > 0 })

    # DC charging
    has_dc = @prompt.yes?("Does this vehicle support DC charging?")
    dc_charger = nil

    if has_dc
      dc_power = @prompt.ask("Enter max DC power (kW):",
        convert: :float,
        validate: ->(v) { v.to_f > 0 })
      dc_ports = @prompt.multi_select("Select DC ports (at least one required):", ChargingDetails::DC_PORTS)
      dc_charger = ChargingDetails.create_dc_charger(dc_ports, dc_power)
    end

    # Charging voltage
    voltage = @prompt.select("Select charging voltage:", ChargingDetails::CHARGING_VOLTAGES)

    {
      "ac_charger" => ChargingDetails.create_ac_charger(ac_ports, ac_phases, ac_power),
      "dc_charger" => dc_charger,
      "charging_voltage" => voltage
    }
  end

  def collect_charging_curve(max_power)
    curve = []
    loop do
      percentage = @prompt.ask("Enter percentage (or 'done'/'back'/'exit'):")
      return percentage if [EXIT_OPTION, BACK_OPTION].include?(percentage)
      break if percentage.downcase == 'done'

      power = @prompt.ask("Enter power at #{percentage}% (or 'back'/'exit'):",
        convert: :float,
        validate: ->(v) { v.to_s.downcase == 'exit' || v.to_s.downcase == 'back' || (v.to_f > 0 && v.to_f <= max_power) })
      return power if [EXIT_OPTION, BACK_OPTION].include?(power)

      curve << {
        "percentage" => percentage.to_i,
        "power" => power
      }
    end

    curve
  end

  def add_another?
    @prompt.yes?("Would you like to add another vehicle?")
  end

  def start_over?
    @prompt.yes?("Would you like to start over?")
  end
end
