---
layout: default
title: Search EV Database
---

<div class="search-container">
    <div class="search-box">
        <input type="text" id="searchInput" placeholder="Search by brand, model, or variant...">
        <div class="search-icon">🔍</div>
    </div>
    
    <div class="filters">
        <div class="filter-group">
            <label><input type="checkbox" id="carFilter" checked> 🚗 Cars</label>
            <label><input type="checkbox" id="bikeFilter" checked> 🏍️ Motorcycles</label>
        </div>
        <div class="filter-group">
            <label>Sort by:
                <select id="sortSelect">
                    <option value="name">Name</option>
                    <option value="battery">Battery Size</option>
                    <option value="consumption">Consumption</option>
                    <option value="dc_power">DC Charging Power</option>
                </select>
            </label>
        </div>
    </div>

    <div id="resultCount" class="result-count"></div>
    <div id="loading" class="loading">Loading vehicle database...</div>
    <div id="results"></div>
</div>

<link rel="stylesheet" href="/assets/css/search.css">
<script src="/assets/js/search.js"></script>
