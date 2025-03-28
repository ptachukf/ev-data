document.addEventListener('DOMContentLoaded', async () => {
    const searchInput = document.getElementById('searchInput');
    const resultsDiv = document.getElementById('results');
    const resultCount = document.getElementById('resultCount');
    const carFilter = document.getElementById('carFilter');
    const bikeFilter = document.getElementById('bikeFilter');
    const microcarFilter = document.getElementById('microcarFilter');
    const sortSelect = document.getElementById('sortSelect');
    const loading = document.getElementById('loading');

    // Get the baseurl from Jekyll configuration
    const baseurl = document.querySelector('meta[name="baseurl"]')?.content || '';
    const GITHUB_RAW_BASE = 'https://raw.githubusercontent.com/KilowattApp/open-ev-data/master/data/v2';

    try {
        // Fetch brands data
        const brandsResponse = await fetch(`${GITHUB_RAW_BASE}/brands.json`);

        if (!brandsResponse.ok) {
            throw new Error('Failed to fetch brands data');
        }

        const brandsData = await brandsResponse.json();

        // Create a map of brand IDs to brand data for quick lookup
        const brandMap = new Map(brandsData.brands.map(brand => [brand.id, brand]));

        // Fetch all model files based on brands
        const modelPromises = brandsData.brands.map(brand => 
            fetch(`${GITHUB_RAW_BASE}/${brand.models_file}`)
                .then(response => {
                    if (!response.ok) {
                        console.warn(`No model file found for ${brand.name} (${brand.models_file})`);
                        return { models: [] };
                    }
                    return response.json();
                })
                .catch(error => {
                    console.warn(`Failed to load models for ${brand.name}:`, error);
                    return { models: [] };
                })
        );

        const modelResponses = await Promise.all(modelPromises);
        
        // Combine all vehicle data
        const evData = modelResponses.flatMap(response => response.models || []);
        
        if (evData.length === 0) {
            throw new Error('No vehicle data found');
        }

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
                if (!carFilter.checked && !bikeFilter.checked && !microcarFilter.checked) {
                    return false;
                }

                const matchesType = 
                    (car.vehicle_type === 'car' && carFilter.checked) ||
                    (car.vehicle_type === 'motorbike' && bikeFilter.checked) ||
                    (car.vehicle_type === 'microcar' && microcarFilter.checked);

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
            resultCount.textContent = `Found ${results.length} vehicle${results.length === 1 ? '' : 's'} (Updated: ${new Date(brandsData.updated_at).toLocaleDateString()})`;
            if (results.length === 0) {
                resultsDiv.innerHTML = '<div class="no-results">No matches found. Try adjusting your search or filters.</div>';
                return;
            }

            resultsDiv.innerHTML = sortedResults.map(car => `
                <div class="car-card">
                    <div class="car-header">
                        <h3>${car.brand} ${car.model} ${car.variant || ''}</h3>
                        <span class="vehicle-type">${
                            car.vehicle_type === 'car' ? '🚗' : 
                            car.vehicle_type === 'motorbike' ? '🏍️' : 
                            '🚐'
                        }</span>
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
        microcarFilter.addEventListener('change', debounceSearch);
        sortSelect.addEventListener('change', debounceSearch);

        // Initialize with all vehicles
        updateResults();

    } catch (error) {
        loading.innerHTML = `Error loading vehicle database: ${error.message}. Please try again later.`;
        console.error('Error:', error);
    }
});