class DataStore
  def initialize(file_path)
    @file_path = file_path
    @data = load_data
    @data["brands"] ||= []
  end

  def save_vehicle(vehicle_data)
    @data["data"] << vehicle_data
    
    unless brand_exists?(vehicle_data["brand"])
      @data["brands"] << {
        "id" => vehicle_data["brand_id"],
        "name" => vehicle_data["brand"]
      }
      @data["brands"].sort_by! { |b| b["name"] }
    end
    
    update_meta
    write_to_file
  end

  def existing_brands
    @data["brands"].map { |b| b["name"] }
  end

  def existing_models(brand)
    @data["data"]
      .select { |v| v["brand"] == brand }
      .map { |v| v["model"] }
      .uniq
      .sort
  end

  def find_or_create_brand_id(brand)
    existing = @data["brands"].find { |b| b["name"] == brand }
    if existing
      existing["id"]
    else
      SecureRandom.uuid
    end
  end

  private

  def brand_exists?(brand_name)
    @data["brands"].any? { |b| b["name"] == brand_name }
  end

  def load_data
    data = JSON.parse(File.read(@file_path))
    data["brands"] ||= []
    data["data"] ||= []
    data["meta"] ||= {}
    data
  end

  def update_meta
    @data["meta"] = {
      "updated_at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      "overall_count" => @data["data"].size
    }
  end

  def write_to_file
    File.write(@file_path, JSON.pretty_generate(@data))
  end
end
