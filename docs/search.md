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

<script>
document.addEventListener('DOMContentLoaded', async () => {
    const searchInput = document.getElementById('searchInput');
    const resultsDiv = document.getElementById('results');
    const resultCount = document.getElementById('resultCount');
    const carFilter = document.getElementById('carFilter');
    const bikeFilter = document.getElementById('bikeFilter');
    const sortSelect = document.getElementById('sortSelect');
    const loading = document.getElementById('loading');

    try {
        const response = await fetch('https://raw.githubusercontent.com/KilowattApp/open-ev-data/refs/heads/master/data/ev-data.json');
        const data = await response.json();
        const evData = data.data;
        loading.style.display = 'none';

        function formatPorts(ports) {
            if (!ports || ports.length === 0) return 'None';
            return ports.map(port => port.replace('_', ' ').toUpperCase()).join(', ');
        }

        function sortResults(results, sortBy) {
            return [...results].sort((a, b) => {
                switch(sortBy) {
                    case 'name':
                        return `${a.brand} ${a.model}`.localeCompare(`${b.brand} ${b.model}`);
                    case 'battery':
                        return b.usable_battery_size - a.usable_battery_size;
                    case 'consumption':
                        return a.energy_consumption.average_consumption - b.energy_consumption.average_consumption;
                    case 'dc_power':
                        const aPower = a.dc_charger?.max_power || 0;
                        const bPower = b.dc_charger?.max_power || 0;
                        return bPower - aPower;
                    default:
                        return 0;
                }
            });
        }

        function search(query) {
            return evData.filter(car => {
                if (!carFilter.checked && !bikeFilter.checked) {
                    return false;
                }

                const matchesType = 
                    (car.vehicle_type === 'car' && carFilter.checked) ||
                    (car.vehicle_type === 'motorbike' && bikeFilter.checked);

                if (!query) {
                    return matchesType;
                }

                query = query.toLowerCase();
                const matchesSearch = car.brand.toLowerCase().includes(query) ||
                    car.model.toLowerCase().includes(query) ||
                    (car.variant || '').toLowerCase().includes(query);
                
                return matchesSearch && matchesType;
            });
        }

        function displayResults(results) {
            const sortedResults = sortResults(results, sortSelect.value);
            resultCount.textContent = `Found ${results.length} vehicle${results.length === 1 ? '' : 's'}`;
            
            if (results.length === 0) {
                resultsDiv.innerHTML = '<div class="no-results">No matches found. Try adjusting your search or filters.</div>';
                return;
            }

            resultsDiv.innerHTML = sortedResults.map(car => `
                <div class="car-card">
                    <div class="car-header">
                        <h3>${car.brand} ${car.model} ${car.variant || ''}</h3>
                        <span class="vehicle-type">${car.vehicle_type === 'car' ? '🚗' : '🏍️'}</span>
                    </div>
                    <div class="car-details">
                        <div class="detail-grid">
                            <div class="detail-item">
                                <span class="label">Battery</span>
                                <span class="value">${car.usable_battery_size} kWh</span>
                            </div>
                            <div class="detail-item">
                                <span class="label">Consumption</span>
                                <span class="value">${car.energy_consumption.average_consumption} kWh/100km</span>
                            </div>
                            ${car.release_year ? `
                                <div class="detail-item">
                                    <span class="label">Release Year</span>
                                    <span class="value">${car.release_year}</span>
                                </div>
                            ` : ''}
                        </div>

                        <div class="charging-section">
                            <h4>Charging Capabilities</h4>
                            <div class="charging-details">
                                <div class="ac-charging">
                                    <span class="label">AC Charging:</span>
                                    <span class="value">${car.ac_charger.max_power} kW</span>
                                    <div class="ports">Ports: ${formatPorts(car.ac_charger.ports)}</div>
                                </div>
                                ${car.dc_charger ? `
                                    <div class="dc-charging">
                                        <span class="label">DC Charging:</span>
                                        <span class="value">${car.dc_charger.max_power} kW</span>
                                        <div class="ports">Ports: ${formatPorts(car.dc_charger.ports)}</div>
                                    </div>
                                ` : ''}
                            </div>
                            ${car.dc_charger?.charging_curve ? `
                                <div class="charging-curve">
                                    <h4>DC Charging Curve</h4>
                                    <div class="curve-points">
                                        ${car.dc_charger.charging_curve.map(point => `
                                            <div class="curve-point">
                                                <span class="percentage">${point.percentage}%</span>
                                                <span class="power">${point.power}kW</span>
                                            </div>
                                        `).join('')}
                                    </div>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                </div>
            `).join('');
        }

        let debounceTimeout;
        function debounceSearch() {
            clearTimeout(debounceTimeout);
            debounceTimeout = setTimeout(() => {
                const query = searchInput.value;
                const results = search(query);
                displayResults(results);
            }, 300);
        }

        function updateResults() {
            const query = searchInput.value;
            const results = search(query);
            displayResults(results);
        }

        searchInput.addEventListener('input', debounceSearch);
        carFilter.addEventListener('change', debounceSearch);
        bikeFilter.addEventListener('change', debounceSearch);
        sortSelect.addEventListener('change', debounceSearch);

        updateResults();

    } catch (error) {
        loading.innerHTML = 'Error loading vehicle database. Please try again later.';
        console.error('Error:', error);
    }
});
</script>

<style>
.search-container {
    margin: 2rem auto;
    max-width: 1200px;
    padding: 0 1rem;
}

.search-box {
    position: relative;
    margin-bottom: 1.5rem;
}

.search-icon {
    position: absolute;
    right: 1rem;
    top: 50%;
    transform: translateY(-50%);
    color: #666;
}

#searchInput {
    width: 100%;
    padding: 1rem;
    padding-right: 2.5rem;
    font-size: 1.1rem;
    border: 2px solid #ddd;
    border-radius: 8px;
    transition: border-color 0.3s ease;
}

#searchInput:focus {
    border-color: #0366d6;
    outline: none;
}

.filters {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin: 1rem 0;
    padding: 1rem;
    background: #f6f8fa;
    border-radius: 8px;
}

.filter-group {
    display: flex;
    gap: 1rem;
}

.filter-group label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

select {
    padding: 0.5rem;
    border-radius: 4px;
    border: 1px solid #ddd;
}

.result-count {
    margin: 1rem 0;
    color: #666;
    font-size: 0.9rem;
}

.loading {
    text-align: center;
    padding: 2rem;
    color: #666;
}

.no-results {
    text-align: center;
    padding: 2rem;
    color: #666;
    background: #f6f8fa;
    border-radius: 8px;
}

.car-card {
    border: 1px solid #eaecef;
    border-radius: 12px;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
    background-color: #fff;
    box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.car-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.car-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
}

.car-header h3 {
    margin: 0;
    color: #0366d6;
    font-size: 1.3rem;
}

.vehicle-type {
    font-size: 1.5rem;
}

.detail-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin-bottom: 1.5rem;
}

.detail-item {
    background: #f6f8fa;
    padding: 0.8rem;
    border-radius: 6px;
}

.detail-item .label {
    display: block;
    color: #666;
    font-size: 0.9rem;
    margin-bottom: 0.3rem;
}

.detail-item .value {
    font-size: 1.1rem;
    font-weight: 500;
}

.charging-section {
    border-top: 1px solid #eaecef;
    padding-top: 1rem;
}

.charging-section h4 {
    margin: 0 0 1rem 0;
    color: #24292e;
}

.charging-details {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin-bottom: 1rem;
}

.ac-charging, .dc-charging {
    background: #f6f8fa;
    padding: 1rem;
    border-radius: 6px;
}

.ports {
    margin-top: 0.5rem;
    font-size: 0.9rem;
    color: #666;
}

.charging-curve {
    margin-top: 1.5rem;
}

.curve-points {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    background: #f6f8fa;
    padding: 1rem;
    border-radius: 6px;
}

.curve-point {
    display: flex;
    flex-direction: column;
    align-items: center;
    background: #fff;
    padding: 0.5rem 0.8rem;
    border-radius: 4px;
    border: 1px solid #eaecef;
}

.curve-point .percentage {
    font-weight: 500;
    color: #0366d6;
}

.curve-point .power {
    font-size: 0.9rem;
    color: #666;
}

@media (max-width: 768px) {
    .filters {
        flex-direction: column;
        gap: 1rem;
    }
    
    .filter-group {
        width: 100%;
        justify-content: space-between;
    }
}
</style>
