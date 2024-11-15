---
layout: default
title: Home
---

# Open EV Data

Open Dataset of Electric Vehicles and their specs.

## Overview

In contrast to ICE cars, electric vehicles have very different behaviors in terms of charging and charging speed. Having reliable data about a car is key for developing EV-related applications.

## Quick Start

The dataset (`data/ev-data.json`) can be freely integrated into ANY application under the terms of our [license](https://github.com/KilowattApp/open-ev-data#license). Attribution is required.

## Contributing

We welcome contributions! Here's how to add a new vehicle:

![CLI Preview](assets/images/cli-preview.gif)

### The full walkthrough

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

## Data Structure

The dataset includes:

* Vehicle identification (Brand, Model, Release Year)
* Battery specifications
* Charging capabilities (AC/DC)
* Charging curves
* Energy consumption data

[View on GitHub](https://github.com/KilowattApp/open-ev-data)
