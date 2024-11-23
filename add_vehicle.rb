#!/usr/bin/env ruby

require 'json'
require 'tty-prompt'
require 'securerandom'
require_relative 'lib/vehicle_creator/cli'
require_relative 'lib/vehicle_creator/data_store'
require_relative 'lib/vehicle_creator/vehicle'
require_relative 'lib/vehicle_creator/charging_details'
require_relative 'lib/vehicle_creator/validators'

class VehicleCreator
  def initialize(data_file = nil, prompt = nil)
    @data_store = DataStore.new(data_file || default_data_file)
    @cli = CLI.new(prompt || TTY::Prompt.new)
  end

  def run
    loop do
      vehicle = Vehicle.new
      
      # Brand selection
      brand = @cli.select_brand(@data_store.existing_brands)
      return if brand == CLI::EXIT_OPTION
      next if brand == CLI::BACK_OPTION
      
      vehicle.add_brand(brand, @data_store.find_or_create_brand_id(brand))

      # Model selection
      model = @cli.select_model(@data_store.existing_models(brand))
      return if model == CLI::EXIT_OPTION
      next if model == CLI::BACK_OPTION
      
      vehicle.add_model(model)

      # Vehicle type
      vehicle_type = @cli.select_vehicle_type
      return if vehicle_type == CLI::EXIT_OPTION
      next if vehicle_type == CLI::BACK_OPTION
      
      vehicle.add_vehicle_type(vehicle_type)

      # Collect details
      if @cli.collect_and_add_details(vehicle)
        @data_store.save_vehicle(vehicle.data)
        break unless @cli.add_another?
      else
        next if @cli.start_over?
        break
      end
    end
  end

  private

  def default_data_file
    File.join(File.dirname(__FILE__), 'data/ev-data.json')
  end
end

if __FILE__ == $PROGRAM_NAME
  VehicleCreator.new.run
end 