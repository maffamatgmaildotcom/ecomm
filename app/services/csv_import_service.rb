class CsvImportService
  require "csv"
  require "zip"

  def import_products(content_type, file, category_id)
    Rails.logger.info "CsvImportService::import_products entering..."
    import_csv(file, category_id) if content_type == "text/csv"
    import_zip(file, category_id) if [ "application/zip", "application/x-zip-compressed" ].include?(content_type)
  end

  def import_csv(file, category_id)
    Rails.logger.info  "CsvImportService::import_csv entering..."
    opened_file = File.open(file)
    options = { headers: true, liberal_parsing: true }
    count = 0
    CSV.foreach(opened_file, **options) do |row|
      # map the CSV columns to your database columns
      product_hash = {}
      name = row["Description"]
      product_hash[:name] = name
      product_hash[:description] = name
      product_hash[:item_number] = row["Item #"]
      product_hash[:year_issued] = row["Year Issued"]
      product_hash[:year_retired] = row["Year Retired"] == "Current" ? nil : row["Year Retired"]
      product_hash[:usd_srp] = row["US SRP"].strip.delete("$.").to_i
      product_hash[:price] = product_hash[:usd_srp]
      product_hash[:cad_srp] = row["CAD SRP"] == "N/A" ? 0 : row["CAD SRP"].strip.delete("$.").to_i
      product_hash[:owned] = false
      product_hash[:category_id] = category_id

      Product.find_or_create_by!(product_hash)
      count += 1
      Rails.logger.info "CsvImportService::import_csv count is #{count}"
      # for performance, you could create a separate job to import each user
      # CsvImportJob.perform_later(user_hash)
    end
  end

  def import_zip(file, category_id)
    Rails.logger.info "CsvImportService::import_zip entering..."
    no_image_tmp_file = nil
    Zip::File.open(file.tempfile) do |zipfile|
      zipfile.each do |entry|
        if entry.file?
          Rails.logger.info "#{entry.name} is a file"
          unless no_image_tmp_file
            no_image_tmp_file = create_no_image_file(entry) if entry.name.starts_with?("no-image")
          end
          attach_image_to_product(entry)
        elsif entry.directory?
          Rails.logger.info "#{entry.name} is a directory"
        elsif entry.symlink?
          Rails.logger.info "#{entry.name} is a symlink"
        end
      end
    end
    #attach_no_image_to_products(no_image_tmp_file, category_id) if no_image_tmp_file
  end

  def create_no_image_file(entry)
    file = Tempfile.new(entry.name)
    entry.extract(file.path) {true}
    file.close
    file
  end

  def attach_image_to_product(entry)
    Rails.logger.info "CsvImportService::attach_image_to_product for #{entry.name} entering..."
    basename = File.basename(entry.name, File.extname(entry.name)) # ditch the extension
    parts = basename.split("_")
    item = parts[0]
    item = item.sub("-", ".") if item[0..1] == "56" && item[7] != '-'
    return if item.nil?

    product = Product.where(item_number: item).first
    return if product.nil?

    Tempfile.open(entry.name) do |tmp|
      # this line creates the temp file
      entry.extract(tmp.path) { true }

      # attaching the temp image file to active record object
      product.images.attach(io: File.open(tmp.path), filename: entry.name)
    end
  end

  def attach_no_image_to_products(no_image_tmp_file, category_id)
    Rails.logger.info "CsvImportService::attach_no_image_to_products entering..."
    Product.where(category_id: category_id).each do |product|
      product.images.attach(io: File.open(no_image_tmp_file.path), filename: "no-image.jpg") unless product.images.attached?
    end
    no_image_tmp_file.unlink
  end
end
