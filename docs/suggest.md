---
layout: default
title: Suggest a Vehicle
---

<div class="suggestion-container">
    <h2>Suggest a New Vehicle</h2>
    <p>Help us expand our database by suggesting a new electric vehicle model.</p>
    
    <form id="vehicleSuggestionForm" onsubmit="return handleSubmit(event)">
        <!-- Required Fields -->
        <div class="form-section">
            <h3>Basic Information</h3>
            <div class="form-group">
                <label for="brand" class="required">Brand</label>
                <select id="brand" name="brand" required>
                    <option value="">Select a brand...</option>
                </select>
            </div>
            
            <div id="modelContainer">
                <!-- Model selection will be dynamically inserted here -->
            </div>
            
            <div class="form-group">
                <label for="vehicleType" class="required">Vehicle Type</label>
                <select id="vehicleType" name="vehicleType" required>
                    <option value="car">Car</option>
                    <option value="motorcycle">Motorcycle</option>
                    <option value="microcar">Microcar</option>
                </select>
            </div>
        </div>

        <!-- Optional Fields -->
        <div class="form-section">
            <h3>Battery & Charging</h3>
            <div class="form-group with-unit" data-unit="kWh">
                <label for="batteryCapacity">Battery Capacity</label>
                <input type="number" id="batteryCapacity" name="batteryCapacity" step="0.1" min="0"
                   placeholder="e.g., 58.0">
            </div>
            
            <div class="form-group with-unit" data-unit="kW">
                <label for="maxAcChargingPower">Max AC Charging Power</label>
                <input type="number" id="maxAcChargingPower" name="maxAcChargingPower" step="0.1" min="0"
                   placeholder="e.g., 11.0">
            </div>
            
            <div class="form-group with-unit" data-unit="kW">
                <label for="maxDcChargingPower">Max DC Charging Power</label>
                <input type="number" id="maxDcChargingPower" name="maxDcChargingPower" step="0.1" min="0"
                   placeholder="e.g., 150.0">
            </div>
        </div>

        <div class="form-section">
            <h3>Performance</h3>
            <div class="form-group with-unit" data-unit="kWh/100km">
                <label for="consumption">Consumption</label>
                <input type="number" id="consumption" name="consumption" step="0.1" min="0"
                   placeholder="e.g., 18.8">
            </div>
        </div>

        <div class="form-section">
            <h3>Additional Information</h3>
            <div class="form-group">
                <label for="sources">Sources (URLs)</label>
                <textarea id="sources" name="sources" 
                   placeholder="e.g., https://ev-database.org/car/1234/example-car&#10;https://www.manufacturer.com/specs/model"></textarea>
            </div>
        </div>

        <button type="submit" class="submit-button">Submit Suggestion</button>
    </form>
</div>

<link rel="stylesheet" href="/assets/css/suggest.css">
<script src="/assets/js/suggest.js"></script> 