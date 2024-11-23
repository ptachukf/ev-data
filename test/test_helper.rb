require 'minitest/autorun'
require 'json'
require 'fileutils'
require 'securerandom'

# Require all lib files
require_relative '../lib/vehicle_creator/data_store'
require_relative '../lib/vehicle_creator/charging_details'
require_relative '../lib/vehicle_creator/validators'
require_relative '../lib/vehicle_creator/vehicle'
require_relative '../lib/vehicle_creator/cli' 