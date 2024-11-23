class DataStore
  def initialize(file_path)
    @file_path = file_path
    @data = load_data
  end

  def save_vehicle(vehicle_data)
    @data["data"] << vehicle_data
    update_meta
    write_to_file
  end

  def existing_brands
    @data["data"].map { |v| v["brand"] }.uniq.sort
  end

  def existing_models(brand)
    @data["data"]
      .select { |v| v["brand"] == brand }
      .map { |v| v["model"] }
      .uniq
      .sort
  end

  def find_or_create_brand_id(brand)
    existing = @data["data"].find { |v| v["brand"] == brand }
    existing ? existing["brand_id"] : SecureRandom.uuid
  end

  private

  def load_data
    JSON.parse(File.read(@file_path))
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
