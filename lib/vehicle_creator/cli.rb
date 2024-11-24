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
      @prompt.ask("Enter new brand name (or 'exit'):") do |q|
        q.validate { |input| Validators.valid_brand_name?(input) }
        q.messages[:valid?] = "Brand name must be a non-empty string"
      end
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
      @prompt.ask("Enter new model name (or 'back'/'exit'):") do |q|
        q.validate { |input| Validators.valid_model_name?(input) }
        q.messages[:valid?] = "Model name must be a non-empty string"
      end
    else
      action
    end
  end

  def select_vehicle_type
    choices = ["car", "motorbike", "microcar", BACK_OPTION, EXIT_OPTION]
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

    # Voltage architecture selection - pass vehicle type
    voltage = select_voltage_architecture(vehicle.data["vehicle_type"])
    return false if [EXIT_OPTION, BACK_OPTION].include?(voltage)
    vehicle.add_voltage_architecture(voltage)

    # Charging curve if DC charging exists
    if charging["dc_charger"]
      curve = collect_charging_curve(
        charging["dc_charger"]["max_power"],
        charging["ac_charger"]["max_power"]
      )
      return false if [EXIT_OPTION, BACK_OPTION].include?(curve)
      vehicle.add_charging_curve(curve)
    end

    true
  end

  def collect_variant_details
    variant = @prompt.ask("Enter variant name (optional):")
    # Empty variant is fine, continue with other details
    
    year = @prompt.ask("Enter release year:", convert: :integer,
      validate: ->(v) { v.to_i.between?(2010, Time.now.year + 1) })
    return BACK_OPTION unless year

    battery = @prompt.ask("Enter usable battery size (kWh):", convert: :float,
      validate: ->(v) { v.to_f > 0 })
    return BACK_OPTION unless battery

    consumption = @prompt.ask("Enter average consumption (kWh/100km):", convert: :float,
      validate: ->(v) { v.to_f > 0 })
    return BACK_OPTION unless consumption

    {
      "variant" => variant || "",  # Use empty string if variant is nil
      "release_year" => year,
      "usable_battery_size" => battery,
      "energy_consumption" => {
        "average_consumption" => consumption
      }
    }
  end

  def collect_charging_details
    details = {}
    
    # Collect AC charging details
    ac_details = collect_ac_details
    return ac_details if [EXIT_OPTION, BACK_OPTION].include?(ac_details)
    details["ac_charger"] = ac_details

    # Collect DC charging details if applicable
    if @prompt.yes?("Does this vehicle support DC charging?")
      dc_details = collect_dc_details
      return dc_details if [EXIT_OPTION, BACK_OPTION].include?(dc_details)
      details["dc_charger"] = dc_details
    end

    # Validate the collected details
    errors = Validators::ChargingValidator.validate_charging_details(details)
    if errors.any?
      errors.each { |error| @prompt.warn(error) }
      return nil
    end

    details
  end

  def start_over?
    @prompt.yes?("Would you like to start over?")
  end

  def add_another?
    @prompt.yes?("Would you like to add another vehicle?")
  end

  def display_and_confirm_vehicle(data)
    puts "\nPlease confirm the vehicle details:"
    puts "-----------------------------------"
    puts "Brand: #{data['brand']}"
    puts "Model: #{data['model']}"
    puts "Type: #{data['vehicle_type']}"
    puts "Variant: #{data['variant']}"
    puts "Release Year: #{data['release_year']}"
    puts "Battery Size: #{data['usable_battery_size']} kWh"
    puts "Energy Consumption: #{data['energy_consumption']['average_consumption']} kWh/100km"
    puts "Charging Voltage: #{data['charging_voltage']} V"
    puts "\nAC Charging:"
    puts "- Ports: #{data['ac_charger']['ports'].join(', ')}"
    puts "- Phases: #{data['ac_charger']['usable_phases']}"
    puts "- Max Power: #{data['ac_charger']['max_power']} kW"
    
    if data['dc_charger']
      puts "\nDC Charging:"
      puts "- Ports: #{data['dc_charger']['ports'].join(', ')}"
      puts "- Max Power: #{data['dc_charger']['max_power']} kW"
      puts "- Charging Curve:"
      data['dc_charger']['charging_curve'].each do |point|
        puts "  #{point['percentage']}%: #{point['power']} kW"
      end
    end

    puts "\n-----------------------------------"

    @prompt.yes?("Would you like to save this vehicle?")
  end

  private

  def collect_ac_details
    ports = collect_ac_ports
    phases = collect_ac_phases
    max_power = collect_ac_power

    {
      "ports" => ports,
      "usable_phases" => phases,
      "max_power" => max_power,
      "power_per_charging_point" => ChargingDetails.calculate_power_per_point(max_power)
    }
  end

  def collect_dc_details
    {
      "ports" => collect_dc_ports,
      "max_power" => collect_dc_power
    }
  end

  def collect_ac_ports
    if @prompt.yes?("Does this vehicle have (type1, type2) AC charging ports?")
      @prompt.multi_select("Select AC ports:", ChargingDetails::AC_PORTS)
    else
      []
    end
  end

  def collect_ac_phases
    @prompt.select("Select AC phases:", [1, 2, 3])
  end

  def collect_ac_power
    @prompt.ask("Enter max AC power (kW):", convert: :float,
      validate: ->(v) { v.to_f > 0 })
  end

  def collect_dc_ports
    @prompt.multi_select("Select DC ports (at least one required):", ChargingDetails::DC_PORTS)
  end

  def collect_dc_power
    @prompt.ask("Enter max DC power (kW):", convert: :float,
      validate: ->(v) { v.to_f > 0 })
  end

  def collect_charging_curve(max_power, ac_power)
    use_default = @prompt.yes?("Would you like to use a default charging curve?")
    return ChargingDetails.default_charging_curve(max_power, ac_power) if use_default

    curve = []
    @prompt.say("Enter charging curve points (minimum 3 points required):")
    @prompt.say("First point must be 0%, last point must be 100%")
    
    loop do
      percentage = @prompt.ask("Enter percentage (0-100, or 'done'/'back'/'exit'):",
        convert: :integer,
        validate: ->(v) { v.to_s.downcase == 'done' || v.to_s.downcase == 'exit' || v.to_s.downcase == 'back' || (v.is_a?(Integer) && v.between?(0, 100)) })
      
      return percentage if [EXIT_OPTION, BACK_OPTION].include?(percentage)
      break if percentage.to_s.downcase == 'done' && curve.length >= 3

      if percentage.to_s.downcase == 'done'
        @prompt.warn("Minimum 3 points required. Please continue.")
        next
      end

      # Check if percentage already exists
      if curve.any? { |point| point["percentage"] == percentage }
        @prompt.warn("Percentage #{percentage}% already exists. Please use a different value.")
        next
      end

      power = @prompt.ask("Enter power at #{percentage}% (max #{max_power} kW):",
        convert: :float,
        validate: ->(v) { v.to_f.positive? && v.to_f <= max_power })

      curve << {
        "percentage" => percentage,
        "power" => power
      }

      @prompt.say("Current curve: #{curve.map { |p| "#{p['percentage']}%: #{p['power']}kW" }.join(' → ')}")
    end

    # Validate the curve
    unless curve.first["percentage"] == 0 && curve.last["percentage"] == 100
      @prompt.warn("Curve must start at 0% and end at 100%. Using default curve instead.")
      return ChargingDetails.default_charging_curve(max_power, ac_power)
    end

    # Sort by percentage to ensure correct order
    curve.sort_by { |point| point["percentage"] }
  end

  def select_voltage_architecture(vehicle_type)
    choices = case vehicle_type
    when "microcar"
      [48, 400]  # Microcars typically use 48V or 400V
    else
      [400, 800]  # Cars and motorbikes use 400V or 800V
    end
    
    @prompt.select("Select voltage architecture (V):", choices)
  end
end
