---
layout: default
title: Data Formats
---

# Data Formats

The Open EV Data project supports two data formats: v1 (legacy) and v2 (current). Both formats are available in the repository.

## V1 Format (Legacy)

The v1 format stores all data in a single JSON file (`data/ev-data.json`) with the following structure:

```json
{
  "meta": {
    "updated_at": "2024-03-28T12:00:00Z",
    "overall_count": 424
  },
  "data": [
    {
      "id": "uuid",
      "brand": "Brand Name",
      "model": "Model Name",
      "vehicle_type": "car",
      "variant": "Variant Name",
      "release_year": 2024,
      "usable_battery_size": 75.0,
      "ac_charger": {
        "ports": ["type2"],
        "max_power": 11.0,
        "usable_phases": 3
      },
      "dc_charger": {
        "ports": ["ccs"],
        "max_power": 150.0,
        "charging_curve": [
          {"percentage": 0, "power": 150.0},
          {"percentage": 80, "power": 70.0}
        ]
      },
      "energy_consumption": {
        "average_consumption": 18.0
      },
      "charging_voltage": 400
    }
  ],
  "brands": [
    {
      "id": "uuid",
      "name": "Brand Name"
    }
  ]
}
```

## V2 Format (Current)

The v2 format splits the data into multiple files for better maintainability:

### Directory Structure

```
data/v2/
├── brands.json           # Brand and meta information
└── models/              # Vehicle model files
    ├── brand1.json
    ├── brand2.json
    └── ...
```

### Brands File (`brands.json`)

```json
{
  "meta": {
    "updated_at": "2024-03-28T12:00:00Z",
    "overall_count": 424
  },
  "brands": [
    {
      "id": "uuid",
      "name": "Brand Name",
      "models_file": "models/brand_name.json"
    }
  ]
}
```

### Model Files (`models/*.json`)

```json
{
  "brand_id": "uuid",
  "brand_name": "Brand Name",
  "models": [
    {
      "id": "uuid",
      "brand": "Brand Name",
      "model": "Model Name",
      "vehicle_type": "car",
      "variant": "Variant Name",
      "release_year": 2024,
      "usable_battery_size": 75.0,
      "ac_charger": {
        "ports": ["type2"],
        "max_power": 11.0,
        "usable_phases": 3
      },
      "dc_charger": {
        "ports": ["ccs"],
        "max_power": 150.0,
        "charging_curve": [
          {"percentage": 0, "power": 150.0},
          {"percentage": 80, "power": 70.0}
        ]
      },
      "energy_consumption": {
        "average_consumption": 18.0
      },
      "charging_voltage": 400
    }
  ]
}
```

## Validation Rules

Both formats enforce the same validation rules:

### General Rules

- All UUIDs must be unique and valid
- Brand references must exist
- Required fields must be present and valid

### Vehicle Rules

- `vehicle_type` must be one of: "car", "motorbike", "microcar"
- `release_year` must be between 2010 and next year
- `usable_battery_size` must be positive
- `charging_voltage` must be one of: 48V (microcars), 400V, 800V

### Charging Rules

- AC charger must have valid ports, phases (1-3), and power values
- DC charger (if present) must have non-empty ports and valid power values
- Charging curve points must have valid percentages (0-100) and power values

## Using the Data

### V1 Format

```ruby
require 'json'
data = JSON.parse(File.read('data/ev-data.json'))
vehicles = data['data']
```

### V2 Format

```ruby
require 'json'

# Read brands and meta information
brands_data = JSON.parse(File.read('data/v2/brands.json'))
brands = brands_data['brands']
meta = brands_data['meta']

# Read all models
models_dir = 'data/v2/models'
all_vehicles = Dir["#{models_dir}/*.json"].flat_map do |file|
  JSON.parse(File.read(file))['models']
end
```

## Contributing

When adding new vehicles, use the provided Ruby scripts:

- `add_vehicle.rb` - Interactive CLI for adding vehicles
- `update_meta.rb` - Updates meta information
- `split_data.rb` - Converts data from v1 to v2 format

All data is validated using Ruby-based validators to ensure integrity.
