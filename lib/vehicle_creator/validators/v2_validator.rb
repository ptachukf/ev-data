require_relative 'charging_validator'
require 'date'

module Validators
  class V2Validator
    class << self
      include Validators::ClassMethods

      def validate_brands_file(brands_file_path)
        data = JSON.parse(File.read(brands_file_path))
        errors = []

        # Validate structure
        unless data.is_a?(Hash) && data['meta'] && data['brands']
          errors << "Invalid brands.json structure. Must contain 'meta' and 'brands' keys"
          return errors
        end

        # Validate meta
        unless data['meta']['updated_at'] && data['meta']['overall_count']
          errors << "Meta must contain 'updated_at' and 'overall_count'"
        end

        # Validate updated_at format (ISO 8601)
        if data['meta']['updated_at']
          begin
            # Attempt to parse the date to ensure it's in a valid ISO 8601 format
            Date.iso8601(data['meta']['updated_at'])
          rescue ArgumentError
            errors << "Invalid date format for updated_at: #{data['meta']['updated_at']}. Must be ISO 8601 format."
          end
        end

        # Validate brands array
        data['brands'].each do |brand|
          errors.concat(validate_brand(brand))
        end

        errors
      end

      def validate_brand(brand)
        errors = []
        
        # Required fields
        unless brand['id'] && brand['name'] && brand['models_file']
          errors << "Brand must contain 'id', 'name', and 'models_file'"
          return errors
        end

        # UUID format
        unless valid_uuid?(brand['id'])
          errors << "Invalid UUID format for brand #{brand['name']}: #{brand['id']}"
        end

        # Models file path format
        unless brand['models_file'].start_with?('models/') && brand['models_file'].end_with?('.json')
          errors << "Invalid models_file path format for brand #{brand['name']}: #{brand['models_file']}"
        end

        errors
      end

      def validate_models_file(models_file_path, brand_id)
        data = JSON.parse(File.read(models_file_path))
        errors = []

        # Validate structure
        unless data.is_a?(Hash) && data['brand_id'] && data['brand_name'] && data['models']
          errors << "Invalid models file structure for #{models_file_path}"
          return errors
        end

        # Validate brand consistency
        unless data['brand_id'] == brand_id
          errors << "Brand ID mismatch in #{models_file_path}"
        end

        # Validate each model
        data['models'].each do |vehicle|
          errors.concat(validate_vehicle(vehicle))
        end

        errors
      end

      def validate_vehicle(vehicle)
        errors = []
        
        # Use shared vehicle validation
        errors.concat(validate_vehicle_base(vehicle))

        # Validate charging details using shared validator
        if vehicle['ac_charger'] || vehicle['dc_charger']
          errors.concat(Validators::ChargingValidator.validate_charging_details(vehicle))
        end

        # Validate energy consumption
        if consumption = vehicle['energy_consumption']
          unless consumption['average_consumption'].is_a?(Numeric) && consumption['average_consumption'].positive?
            errors << "Invalid energy consumption for #{vehicle['brand']} #{vehicle['model']}"
          end
        else
          errors << "Missing energy consumption for #{vehicle['brand']} #{vehicle['model']}"
        end

        errors
      end

      private

      def valid_uuid?(uuid)
        uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
        uuid_regex.match?(uuid)
      end
    end
  end
end 