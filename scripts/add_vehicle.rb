#!/usr/bin/env ruby

require 'json'
require 'tty-prompt'
require 'securerandom'

class VehicleCreator
  BACK_OPTION = "↩️  Go back"
  EXIT_OPTION = "❌ Exit"

  def initialize
    @prompt = TTY::Prompt.new
    @data_file = File.join(File.dirname(__FILE__), '../data/ev-data.json')
    @json_data = JSON.parse(File.read(@data_file))
    @existing_brands = @json_data["data"].map { |v| v["brand"] }.uniq.sort
    @existing_models = @json_data["data"].map { |v| "#{v["brand"]} #{v["model"]}" }.uniq.sort
  end

  def run
    loop do
      vehicle_data = {
        "id" => SecureRandom.uuid,
        "type" => "bev"
      }

      # Brand selection
      brand = select_brand
      return if brand == EXIT_OPTION
      next if brand == BACK_OPTION
      vehicle_data["brand"] = brand
      vehicle_data["brand_id"] = find_or_create_brand_id(brand)

      # Model selection
      model = select_model(brand)
      return if model == EXIT_OPTION
      next if model == BACK_OPTION
      vehicle_data["model"] = model

      # Vehicle type
      vehicle_type = select_vehicle_type
      return if vehicle_type == EXIT_OPTION
      next if vehicle_type == BACK_OPTION
      vehicle_data["vehicle_type"] = vehicle_type

      # Basic variant details
      variant_details = collect_variant_details(vehicle_data)
      return if variant_details == EXIT_OPTION
      next if variant_details == BACK_OPTION
      vehicle_data.merge!(variant_details)

      # Charging details
      charging_details = collect_charging_details(vehicle_data)
      return if charging_details == EXIT_OPTION
      next if charging_details == BACK_OPTION
      vehicle_data.merge!(charging_details)

      # Optional charging curve
      if vehicle_data["dc_charger"] && prompt_charging_curve?
        curve_data = collect_charging_curve(vehicle_data)
        return if curve_data == EXIT_OPTION
        next if curve_data == BACK_OPTION
        vehicle_data["dc_charger"].merge!(curve_data)
      end

      # Confirm and save
      if confirm_entry(vehicle_data)
        save_vehicle(vehicle_data)
        puts "\n✅ Vehicle successfully added!"
        break if !@prompt.yes?("Would you like to add another vehicle?")
      else
        next if @prompt.yes?("Would you like to start over?")
        break
      end
    end
  end

  private

  def select_brand
    choices = [
      "Choose existing brand",
      "Add new brand",
      EXIT_OPTION
    ]

    choice = @prompt.select("Select action for brand:", choices)
    return choice if choice == EXIT_OPTION

    if choice == "Choose existing brand"
      @prompt.select("Select brand:", [
        *@existing_brands,
        BACK_OPTION,
        EXIT_OPTION
      ])
    else
      @prompt.ask("Enter new brand name (or 'exit'):") do |q|
        q.validate(/\A[A-Za-z0-9\s\-]+\z/)
        q.messages[:valid?] = "Brand name can only contain letters, numbers, spaces, and hyphens"
        q.convert -> (input) {
          return EXIT_OPTION if input.downcase == 'exit'
          return BACK_OPTION if input.downcase == 'back'
          input
        }
      end
    end
  end

  def select_model(brand)
    loop do
      choices = [
        "Choose existing model",
        "Add new model",
        BACK_OPTION,
        EXIT_OPTION
      ]

      choice = @prompt.select("Select action for model:", choices)
      return choice if [BACK_OPTION, EXIT_OPTION].include?(choice)

      if choice == "Choose existing model"
        existing_brand_models = @json_data["data"]
          .select { |v| v["brand"] == brand }
          .map { |v| v["model"] }
          .uniq
          .sort

        selected_model = @prompt.select("Select model:", [
          *existing_brand_models,
          BACK_OPTION,
          EXIT_OPTION
        ])
        
        return selected_model if [EXIT_OPTION].include?(selected_model)
        next if selected_model == BACK_OPTION  # Go back to model action selection
        return selected_model
      else
        new_model = @prompt.ask("Enter new model name (or 'back'/'exit'):") do |q|
          q.validate(/\A[A-Za-z0-9\s\-]+\z/)
          q.messages[:valid?] = "Model name can only contain letters, numbers, spaces, and hyphens"
          q.convert -> (input) {
            return EXIT_OPTION if input.downcase == 'exit'
            return BACK_OPTION if input.downcase == 'back'
            input
          }
        end
        
        return new_model if [EXIT_OPTION].include?(new_model)
        next if new_model == BACK_OPTION  # Go back to model action selection
        return new_model
      end
    end
  end

  def collect_variant_details(data)
    details = {}
    
    puts "\nEntering variant details:"
    variant = @prompt.ask("Enter variant name (or 'back'/'exit'):")
    return EXIT_OPTION if variant.downcase == 'exit'
    return BACK_OPTION if variant.downcase == 'back'
    
    year = @prompt.ask("Enter release year (or 'back'/'exit'):", convert: :integer) do |q|
      q.validate { |v| v.to_s.downcase == 'exit' || v.to_s.downcase == 'back' || v.to_i.between?(2010, Time.now.year + 1) }
    end
    return EXIT_OPTION if year.to_s.downcase == 'exit'
    return BACK_OPTION if year.to_s.downcase == 'back'

    battery_size = @prompt.ask("Enter usable battery size (kWh) (or 'back'/'exit'):", convert: :float) do |q|
      q.validate { |v| v.to_f > 0 }
    end
    return EXIT_OPTION if battery_size.to_s.downcase == 'exit'
    return BACK_OPTION if battery_size.to_s.downcase == 'back'

    consumption = @prompt.ask("Enter average consumption (kWh/100km) (or 'back'/'exit'):", convert: :float) do |q|
      q.validate { |v| v.to_f > 0 }
    end
    return EXIT_OPTION if consumption.to_s.downcase == 'exit'
    return BACK_OPTION if consumption.to_s.downcase == 'back'

    details["variant"] = variant
    details["release_year"] = year
    details["usable_battery_size"] = battery_size
    details["energy_consumption"] = {
      "average_consumption" => consumption
    }

    details
  end

  def collect_charging_details(data)
    charging_data = {}

    # AC Charging
    loop do
      ac_ports = @prompt.multi_select("Select AC ports (at least one required):", ["type1", "type2"])
      if ac_ports.empty?
        puts "❌ Please select at least one AC port"
        next
      end
      
      charging_data["ac_charger"] = {
        "usable_phases" => @prompt.select("Select AC phases:", [1, 2, 3]),
        "ports" => ac_ports,
        "max_power" => @prompt.ask("Enter max AC power (kW):", convert: :float) do |q|
          q.validate { |v| v.to_f > 0 }
        end
      }
      break
    end
    
    # Add power_per_charging_point based on max_power
    charging_data["ac_charger"]["power_per_charging_point"] = generate_power_per_charging_point(charging_data["ac_charger"]["max_power"])

    # DC Charging
    if @prompt.yes?("Does this vehicle support DC charging?")
      dc_max_power = @prompt.ask("Enter max DC power (kW):", convert: :float) do |q|
        q.validate { |v| v.to_f > 0 }
      end

      loop do
        dc_ports = @prompt.multi_select("Select DC ports (at least one required):", ["ccs", "chademo", "tesla_suc", "tesla_ccs"])
        if dc_ports.empty?
          puts "❌ Please select at least one DC port"
          next
        end

        charging_data["dc_charger"] = {
          "ports" => dc_ports,
          "max_power" => dc_max_power,
          "charging_curve" => [
            { "percentage" => 0, "power" => dc_max_power * 0.95 },
            { "percentage" => 75, "power" => dc_max_power },
            { "percentage" => 100, "power" => charging_data["ac_charger"]["max_power"] }
          ],
          "is_default_charging_curve" => true
        }
        break
      end
    else
      charging_data["dc_charger"] = nil
    end

    charging_data["charging_voltage"] = @prompt.select("Select charging voltage:", [400, 800])

    charging_data
  end

  def prompt_charging_curve?
    choices = [
      "Yes",
      "No",
      BACK_OPTION,
      EXIT_OPTION
    ]
    choice = @prompt.select("Would you like to add a custom DC charging curve?", choices)
    return EXIT_OPTION if choice == EXIT_OPTION
    return BACK_OPTION if choice == BACK_OPTION
    choice == "Yes"
  end

  def collect_charging_curve(data)
    curve = []
    puts "\nEnter charging curve points (0-100%):"
    
    loop do
      percentage = @prompt.ask("Enter percentage (or 'done'/'back'/'exit'):")
      return EXIT_OPTION if percentage.downcase == 'exit'
      return BACK_OPTION if percentage.downcase == 'back'
      break if percentage.downcase == 'done'

      percentage = percentage.to_i
      next unless percentage.between?(0, 100)

      power = @prompt.ask("Enter power at #{percentage}% (or 'back'/'exit'):", convert: :float) do |q|
        q.validate { |v| v.to_s.downcase == 'exit' || v.to_s.downcase == 'back' || (v.to_f > 0 && v.to_f <= data["dc_charger"]["max_power"]) }
      end
      return EXIT_OPTION if power.to_s.downcase == 'exit'
      return BACK_OPTION if power.to_s.downcase == 'back'

      curve << { "percentage" => percentage, "power" => power }
    end

    if curve.any?
      {
        "charging_curve" => curve.sort_by { |point| point["percentage"] },
        "is_default_charging_curve" => false
      }
    else
      {
        "charging_curve" => [
          { "percentage" => 0, "power" => data["dc_charger"]["max_power"] * 0.95 },
          { "percentage" => 75, "power" => data["dc_charger"]["max_power"] },
          { "percentage" => 100, "power" => data["ac_charger"]["max_power"] }
        ],
        "is_default_charging_curve" => true
      }
    end
  end

  def generate_power_per_charging_point(max_power)
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

  def find_or_create_brand_id(brand)
    existing = @json_data["data"].find { |v| v["brand"] == brand }
    existing ? existing["brand_id"] : SecureRandom.uuid
  end

  def confirm_entry(data)
    puts "\nReview new vehicle entry:"
    puts JSON.pretty_generate(data)
    @prompt.yes?("Would you like to save this entry?")
  end

  def save_vehicle(data)
    @json_data["data"] << data
    File.write(@data_file, JSON.pretty_generate(@json_data))
  end

  def select_vehicle_type
    @prompt.select("Select vehicle type:", [
      "car",
      "motorbike",
      BACK_OPTION,
      EXIT_OPTION
    ])
  end
end

# Run the script
VehicleCreator.new.run 