# Open EV Data

[![Ruby Tests](https://github.com/KilowattApp/open-ev-data/actions/workflows/test.yml/badge.svg)](https://github.com/KilowattApp/open-ev-data/actions/workflows/test.yml)
[![Sponsor](https://img.shields.io/github/sponsors/KilowattApp?label=Sponsor&logo=GitHub)](https://github.com/sponsors/KilowattApp)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/xoCRGwybBs)

A comprehensive database of electric vehicle specifications, focusing on charging capabilities and energy consumption.

In contrast to ICE cars, electric vehicles have very different behaviors in terms of charging and charging speed. Having reliable data about a car is key for developing EV-related applications.

This dataset (`data/ev-data.json`) can be freely integrated into ANY
application under the terms of our [license](#license). Attribution is required.

This data is used for [Kilowatt – Electric Car Timer](https://apps.apple.com/us/app/kilowatt-electric-car-timer/id1502312657?itsct=apps_box_link&itscg=30200) app available on the Apple App Store.

## Available Data

At the moment mostly charging related data is available. Feel free to add more
data if you need it!

[You can also search through our data set!](https://kilowattapp.github.io/open-ev-data/search).

## Data Formats

### V1 Format (Legacy)

The original format is available in `data/ev-data.json`. This single file contains all vehicle and brand information.

### V2 Format (Current)

The current format splits the data into multiple files for better maintainability. See [V2 Format Documentation](data/v2/README.md) for details.

## Data Structure

Each vehicle entry contains:

- Basic information (brand, model, variant, release year)
- Battery specifications
- AC charging capabilities
- DC charging capabilities (optional)
- Energy consumption data

## Validation

The data is validated using Ruby-based validators that ensure:

- Data integrity and consistency
- Valid charging specifications
- Correct relationships between brands and vehicles
- Proper UUID formats
- Valid charging curves and power levels

## Scripts

- `scripts/update_meta.rb`: Updates meta information in the v2 format
- `scripts/split_data.rb`: Converts data from v1 to v2 format

## Change Requests

Please file an issue if you have a change request.

## Contributing

We are always looking for people who want to contribute to the
project! Feel free to open a PR to contribute!

### Documentation

For detailed documentation, please visit our [Open EV Data Website](https://kilowattapp.github.io/open-ev-data).

## License

This dataset is released under the MIT License with Attribution Requirement. This means you can freely use this data in your projects, but you must include attribution to Open EV Data.

### Attribution Requirements

When using this dataset in your project, you must include a clear and visible attribution to "[Open EV Data](https://github.com/KilowattApp/open-ev-data)" in one of the following locations:

- About page or section
- Documentation
- README file

See the [LICENSE](LICENSE) file for the complete terms.
