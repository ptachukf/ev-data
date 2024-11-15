# Open EV Data

[![Ruby Tests](https://github.com/KilowattApp/open-ev-data/actions/workflows/test.yml/badge.svg)](https://github.com/KilowattApp/open-ev-data/actions/workflows/test.yml)
[![Sponsor](https://img.shields.io/github/sponsors/KilowattApp?label=Sponsor&logo=GitHub)](https://github.com/sponsors/KilowattApp)

Open Dataset of Electric Vehicles and their specs.

In contrast to ICE cars, electric vehicles have very different behavious in
terms of charging and charging speed. Hence having reliable data about a car is
the key for developing EV-related applications.

This dataset (`data/ev-data.json`) can be freely integrated into ANY
application under the terms of our [license](#license). Attribution is required.

This data is used for [Kilowatt – Electric Car Timer](https://apps.apple.com/us/app/kilowatt-electric-car-timer/id1502312657?itsct=apps_box_link&itscg=30200) app available on the Apple App Store.

This project started as a fork of the side project of the charging price and tariff comparison platform
[Chargeprice](https://www.chargeprice.app) who stopped maintaining this project.

## Available Data

At the moment mostly charging related data is available. Feel free to add more
data if you need it!

* ID: Random UUID
* Brand
* Vehicle Type (car, motorbike)
* Type (BEH, PHEV)
* Model
* Release Year: Mainly to distinquish models with the same name.
* Variant: Bigger battery, optional faster on-board charger etc.
* Usable Battery Size: in kWh
* Average Energy Consumption: in kWh/100km
* AC Charger: Details about the on-board charger.
  * Usable Phases: No. of usable phases for AC charging. Allowed values: 1,2,3
  * Ports: Allowed values: `type1`, `type2`
  * Max Power: in kW
  * Power per Charging Point: Charging power at common charging points. Key and
    Value in kW.
* DC Charger: `null` if the car doesn't support DC charging
  * Ports: Allowed values: `ccs`, `chademo`, `tesla_suc`, `tesla_ccs`
  * Max Power: in kW
  * Charging Curve: Simplified charging behaviour based on various charging
    curve charts (e.g. Fastned). If no charging curve data is available, the
    default curve is assumed to be: 0%: 95% of max. DC power, 75%: max. DC
    power, 100%: max. AC power.
    * percentage: Charging level of battery in percentage
    * power: in kW
  * Is Default Charging Curve: `true` if the charging curve is based on the
    default curve instead of real measured data.

## Change Requests

Please file an issue if you have a change request.

## Contributing

We are always looking for people who want to contribute to the
project! Feel free to open a PR to contribute!

## Updating the data

### The full walkthrough

![CLI Preview](sources/cli-preview.gif)

* Look up as much data as you can find about the model or model variant of the vehicle you want to add
* Clone this repository
* Make sure you have Ruby version 3 or higher installed
* Install the dependencies: `bundle install`
* Create a git branch for your update: `git checkout -b adding-my-missing-car-model`
* Run the `add_vehicle.rb` script and answer the questions about the model you are adding
* Once you've added the missing data run the tests to validate: `ruby scripts/test/validators/ev_data_test.rb`
* Commit and push your changes: `git commit -am "my JSON updates"`
* Finally create a pull request with your updated JSON data

### TLDR

* Install the dependencies: `bundle install`
* Run the `add_vehicle.rb` script and answer the questions about the model you are adding
* Create a pull request with your updated JSON data

## License

This dataset is released under the MIT License with Attribution Requirement. This means you can freely use this data in your projects, but you must include attribution to Open EV Data.

### Attribution Requirements

When using this dataset in your project, you must include a clear and visible attribution to "[Open EV Data](https://github.com/KilowattApp/open-ev-data)" in one of the following locations:

* About page or section
* Documentation
* README file

See the [LICENSE](LICENSE) file for the complete terms.
