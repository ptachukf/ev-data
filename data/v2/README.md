# Open EV Data Format v2

This directory contains the v2 format of the Open EV Data, which uses a sharded approach to store electric vehicle data. The data is split into multiple files for better maintainability and easier updates.

## Structure

```
data/v2/
├── brands.json           # Contains brand information and references to model files
└── models/              # Directory containing individual brand model files
    ├── audi.json
    ├── bmw.json
    ├── tesla.json
    └── ...
```

## File Formats

### brands.json

The main index file containing brand information and references to model files.

```json
{
  "meta": {
    "updated_at": "2024-03-28T15:11:00Z",  // ISO 8601 timestamp
    "overall_count": 424                    // Total number of vehicles across all brands
  },
  "brands": [
    {
      "id": "f37896c3-6bc5-45e1-b442-b9cbc38e3a7c",  // UUID v4
      "name": "Tesla",                                 // Brand name
      "models_file": "models/tesla.json"              // Reference to the models file
    },
    // ... more brands
  ]
}
```

### Model Files (e.g., models/tesla.json)

Each brand has its own JSON file containing all models for that brand.

```json
{
  "brand_id": "f37896c3-6bc5-45e1-b442-b9cbc38e3a7c",  // Must match the brand ID in brands.json
  "brand_name": "Tesla",                                 // Must match the brand name in brands.json
  "models": [
    {
      "id": "fbffc80f-062d-ed16-d6df-5f621bb35848",    // UUID v4
      "brand": "Tesla",                                 // Must match brand_name
      "vehicle_type": "car",                           // One of: "car", "motorbike", "microcar"
      "brand_id": "f37896c3-6bc5-45e1-b442-b9cbc38e3a7c",  // Must match the brand ID
      "model": "Model 3",                              // Model name
      "release_year": 2023,                            // Year between 2010 and current year + 1
      "variant": "",                                   // Optional variant name
      "usable_battery_size": 57.5,                    // Battery size in kWh
      "charging_voltage": 400,                         // One of: 48V (microcar), 400V, 800V
      "ac_charger": {
        "usable_phases": 3,                           // Number of usable phases (1-3)
        "ports": ["type2"],                           // Array of AC port types
        "max_power": 11                               // Maximum AC charging power in kW
      },
      "dc_charger": {                                // Optional DC charging capabilities
        "ports": ["ccs"],                            // Array of DC port types (must not be empty if present)
        "max_power": 250,                            // Maximum DC charging power in kW
        "is_default_charging_curve": false,          // Whether the charging curve is a default one
        "charging_curve": [                          // Array of charging curve points
          {
            "percentage": 0,                         // State of charge percentage (0-100)
            "power": 250                             // Power at this percentage (≤ max_power)
          },
          // ... more curve points
        ]
      },
      "energy_consumption": {
        "average_consumption": 13.7,                 // Average consumption in kWh/100km
        "range": 545                                 // Optional WLTP range in km
      }
    }
    // ... more models
  ]
}
```

## Validation Rules

### General Rules

- All UUIDs must be valid v4 UUIDs
- All file references in `brands.json` must exist
- Brand IDs and names must be consistent across files
- The `overall_count` in meta must match the total number of vehicles

### Vehicle Rules

- Required fields: id, brand, model, vehicle_type, brand_id, usable_battery_size, ac_charger, energy_consumption, charging_voltage
- `vehicle_type` must be one of: "car", "motorbike", "microcar"
- `release_year` must be between 2010 and current year + 1
- `usable_battery_size` must be positive
- `charging_voltage` must be appropriate for the vehicle type:
  - Microcar: 48V or 400V
  - Car/Motorbike: 400V or 800V

### Charging Rules

- AC charger is required and must have:
  - `usable_phases`: 1-3
  - `ports`: Array of supported port types
  - `max_power`: Positive number
  - `power_per_charging_point`: Optional field (no longer required)
- DC charger is optional but if present must have:
  - `ports`: Non-empty array of supported port types
  - `max_power`: Positive number
  - `charging_curve`: Array of percentage/power points
    - Percentages must be 0-100
    - Power must be ≤ max_power

### Port Types

- AC ports: "type1", "type2"
- DC ports: "ccs", "chademo", "tesla_suc"

## Maintenance

The repository includes scripts to help maintain the data:

- `scripts/update_meta.rb`: Updates the meta information in brands.json
- `scripts/split_data.rb`: Converts from v1 format to v2 format
- `scripts/merge_data.rb`: Converts from v2 format back to v1 format

### Conversion Scripts

#### Split Data (V1 → V2)

The `split_data.rb` script splits the single v1 format file into the multi-file v2 format:

```bash
ruby scripts/split_data.rb
```

This creates:

- `data/v2/brands.json` - Contains brand information and references to model files
- `data/v2/models/*.json` - Individual files for each brand's models

#### Merge Data (V2 → V1)

The `merge_data.rb` script combines the v2 format files back into the single v1 format file:

```bash
ruby scripts/merge_data.rb [options]
```

Options:

- `-i, --input DIRECTORY` - Input directory containing V2 format data (default: data/v2)
- `-o, --output FILE` - Output file path for V1 format data (default: data/ev-data.json)
- `-v, --verbose` - Enable verbose output
- `-f, --fix-duplicates` - Fix duplicate IDs by generating new UUIDs
- `-h, --help` - Show help message

This is useful when you've been modifying data in the v2 format and need to update the v1 format file.

## Validation

Use the V2Validator class to validate the data:

```ruby
errors = Validators::V2Validator.validate_brands_file('data/v2/brands.json')
if errors.empty?
  puts "Data is valid!"
else
  puts "Validation errors found:"
  puts errors
end
```
