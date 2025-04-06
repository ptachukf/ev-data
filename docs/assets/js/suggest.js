document.addEventListener('DOMContentLoaded', async function() {
  const form = document.getElementById('vehicleSuggestionForm');
  const brandSelect = document.getElementById('brand');
  const modelContainer = document.getElementById('modelContainer');
  let vehicleData = [];
  
  try {
    // Fetch the data
    const response = await fetch('https://raw.githubusercontent.com/KilowattApp/open-ev-data/refs/heads/master/data/ev-data.json');
    const data = await response.json();
    vehicleData = data.data;
    
    // Get unique brands and sort them
    const brands = [...new Set(vehicleData.map(vehicle => vehicle.brand))].sort();
    
    // Populate brands dropdown
    brands.forEach(brand => {
      const option = document.createElement('option');
      option.value = brand;
      option.textContent = brand;
      brandSelect.appendChild(option);
    });

  } catch (error) {
    console.error('Error loading brands:', error);
    const option = document.createElement('option');
    option.textContent = 'Error loading brands';
    brandSelect.appendChild(option);
  }

  // Function to create model selection UI
  function createModelSelection(brand) {
    // Get all models for selected brand
    const models = [...new Set(vehicleData
      .filter(vehicle => vehicle.brand === brand)
      .map(vehicle => vehicle.model)
    )].sort();

    // Create the HTML for model selection
    const html = `
      <div class="form-group">
        <label for="modelSelect" class="required">Model</label>
        <select id="modelSelect" name="modelSelect" required>
          <option value="">Select a model...</option>
          ${models.map(model => `<option value="${model}">${model}</option>`).join('')}
          <option value="new">➕ Add new model</option>
        </select>
      </div>
      <div class="form-group" id="newModelInput" style="display: none;">
        <label for="model" class="required">New Model Name</label>
        <input type="text" id="model" name="model" required>
      </div>
    `;

    modelContainer.innerHTML = html;

    // Add event listener for model select
    const modelSelect = document.getElementById('modelSelect');
    const newModelInput = document.getElementById('newModelInput');
    const modelInput = document.getElementById('model');

    modelSelect.addEventListener('change', function() {
      if (this.value === 'new') {
        newModelInput.style.display = 'grid';
        modelInput.required = true;
        modelInput.value = '';
      } else {
        newModelInput.style.display = 'none';
        modelInput.required = false;
        modelInput.value = this.value;
      }
    });
  }

  // Handle brand selection
  brandSelect.addEventListener('change', function() {
    if (this.value) {
      createModelSelection(this.value);
    } else {
      modelContainer.innerHTML = '';
    }
  });
  
  // Rest of the form submission code...
  if (form) {
    form.addEventListener('submit', function(e) {
      e.preventDefault();
      
      const formData = new FormData(form);
      const modelSelect = document.getElementById('modelSelect');
      const modelValue = modelSelect.value === 'new' ? 
        document.getElementById('model').value : 
        modelSelect.value;
      
      const title = `Vehicle Suggestion: ${formData.get('brand')} ${modelValue}`;
      const body = `
Vehicle Details:
- Brand: ${formData.get('brand')}
- Model: ${modelValue}
- Vehicle Type: ${formData.get('vehicleType')}
- Battery Capacity: ${formData.get('batteryCapacity')} kWh
- AC Charging Power: ${formData.get('maxAcChargingPower')} kW
- DC Charging Power: ${formData.get('maxDcChargingPower')} kW
- Consumption: ${formData.get('consumption')} kWh/100km

Sources:
${formData.get('sources')}
      `.trim();
      
      const issueUrl = `https://github.com/KilowattApp/open-ev-data/issues/new?title=${encodeURIComponent(title)}&body=${encodeURIComponent(body)}`;
      
      window.open(issueUrl, '_blank');
      
      const successMsg = document.createElement('div');
      successMsg.className = 'success';
      successMsg.textContent = 'Thank you for your suggestion! You will be redirected to GitHub to create an issue.';
      form.appendChild(successMsg);
      
      form.reset();
      modelContainer.innerHTML = '';
    });
  }
}); 